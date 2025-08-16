## Holds state of current combat (or the information that there is no combat).
## Many nodes expect this node to be provided via DI.
class_name Combat
extends Node

var di := DI.new(self)

@onready var _controlled_characters := di.inject(ControlledCharacters) as ControlledCharacters
@onready var _game_instance := di.inject(GameInstance) as GameInstance
@onready var _spawned_npcs := di.inject(SpawnedNpcs) as SpawnedNpcs
@onready var _base_level := di.inject(BaseLevel) as BaseLevel

## When combat state is defined, the combat is considered as active. All
## information that should be kept when saving the game midcombat should be in
## this combat state instance rather than in this node.
@export var state: CombatState = null

var active: bool:
	get:
		return !!state

## Signal emitted whenever turn (and thus sometimes even round) progresses
signal progressed()

## Signal emitted when combat becomes active or list of participants change in
## active combat
signal combat_participants_changed()

signal ended()

var _log := global.message_log()


## Announce that given NPC wants to join a combat, collecting its neighbours
## and either activate a new combat or add to existing.
##
## When skip_signals is true, the game won't actually react to the combat
## starting.
func activate(character: NpcCharacter, skip_signals: bool = false) -> void:
	if _base_level.cutscene_active:
		# temp, need to rethink this a little
		return

	var participants := _find_npcs_to_add(character).filter(func (p: NpcCharacter) -> bool: return not has_npc(p))
	if participants.size() == 0:
		push_warning("Trying to activate combat with all characters already in")
		return;

	if state:
		for npc: NpcCharacter in participants:
			_add_npc(npc)
			emit_trigger(CombatStartedTrigger.new(), npc)
	else:
		# todo: include who was noticed, but currently we are not propagating
		# that information => create some InitCombatData class or whatever.
		_log.system("Your party has been noticed by enemy")
		state = CombatState.new()

		state.pc_participants.assign(_controlled_characters.get_characters())
		state.npc_participants.assign(participants)
		_update_initiatives()
		_update_initial_hp()
		# todo: this may not be a good idea, this will result in soo many
		# iterations: chara_n * chara_n * modifier_n lol
		for participant in get_participants():
			emit_trigger(CombatStartedTrigger.new(), participant)
		emit_trigger(RoundStartedTrigger.new())

	if not skip_signals:
		combat_participants_changed.emit()


## Get all current participants if the combat is active
func get_participants() -> Array[GameCharacter]:
	if state:
		return state.participant_order
	else:
		return []


func has_participant(chara: GameCharacter) -> bool:
	return state.initiatives.has(chara)


func has_npc(npc: NpcCharacter) -> bool:
	return state and state.npc_participants.has(npc)


func get_hp(character: GameCharacter) -> int:
	assert(state, "Cannot get HP when combat not active")
	return state.character_hp[character]


## Get current turn's character
func get_active_character() -> GameCharacter:
	assert(state, "Cannot get active character when combat not active")
	return state.participant_order[state.turn_number]


## Number of available steps assuming player spends all their neutral actions
## + already gained steps
func get_available_steps() -> float:
	var available_actions := state.turn_actions.filter(func (ac: CombatAction) -> bool: return ac.attribute == null and not ac.used)
	return state.steps + available_actions.size() * Ruleset.calculate_steps_per_action(get_active_character())


## Use neutral action to gain steps
func use_action_for_steps() -> void:
	var available_action := state.turn_actions.filter(func (ac: CombatAction) -> bool: return ac.attribute == null and not ac.used)[0] as CombatAction
	available_action.used = true
	state.steps += Ruleset.calculate_steps_per_action(get_active_character())


# Returns false when there is currently some action happening and player
# shouldn't be in any kind of control (e.g. mid-attack, character movement, AI
# turn etc...)
func is_free() -> bool:
	if active and _active_trigger_count == 0:
		var character := get_active_character()
		return character is PlayableCharacter and (character.action is CharacterCombatReady or character.action is CharacterMovement)
	else:
		return false


## Get number of available actions per each attribute. If used when combat not
## active, dict as if in combat with no actions used.
##
## todo: maybe storing actions in combat state was a bad idea... consider
## moving into character resource... ACTUALLY I may want to introduce reactions
## that require turn actions which means the (un)used state of turn action
## needs to outlive the turn!
func get_turn_action_dict(character: GameCharacter) -> Dictionary[CharacterAttribute, int]:
	var list: Array[CombatAction] = []
	if active:
		if get_active_character() == character:
			list = state.turn_actions
	else:
		list = Ruleset.calculate_turns(character)

	var out: Dictionary[CharacterAttribute, int] = {}
	for action in list:
		if not action.used:
			out[action.attribute] = out.get(action.attribute, 0) + 1
	return out


# End current turn, increasing the turn number (or round if this was last turn
# in the round)
func end_turn() -> void:
	assert(state, "Cannot end turn when combat is not active")
	# needs to be >= since if last participant dies in their turn, it results
	# in turn > count
	if state.turn_number + 1 >= state.participant_order.size():
		state.turn_number = 0
		state.round_number += 1
	else:
		state.turn_number += 1
	for character in get_participants():
		for onset in character.static_buffs:
			var buff := character.static_buffs[onset]
			if onset.is_combat():
				var last_round := onset.starting_round + buff.round_duration
				if last_round < state.round_number or last_round == state.round_number and state.turn_number >= onset.starting_turn:
					character.static_buffs.erase(onset)
					_log.system("%s lost %s" % [character.name, buff.name])
	progressed.emit()
	emit_trigger(RoundStartedTrigger.new())


## Deal dmg damage to given character. If the character is not part of current
## combat, add it (and start the combat if it wasn't active until now)
##
## todo: wrap dmg with more info about it (including the source chara/ability)
## into some structure.
func deal_damage(character: GameCharacter, dmg: int, src_character: GameCharacter = character) -> void:
	var npc := character as NpcCharacter
	var pc := character as PlayableCharacter

	if not state:
		if pc:
			_log.dialogue(character.name, Color.ROYAL_BLUE, "[looks disappointed]")
			# todo: properly implement "try save against some skill or add
			# injury, dc should be based on dmg vs max hp ratio?"
			return
		elif npc:
			npc.enemy = true
			activate(npc, true)

	if state:
		if npc and not npc in state.npc_participants:
			activate(npc)
		assert(character in state.character_hp, "Affecting character that is not in combat")
		state.character_hp[character] -= dmg
		if dmg >= 0:
			_log.system("%s lost %s HP" % [character.name, dmg])
		else:
			_log.system("%s gained %s HP" % [character.name, dmg])
		# todo: still dunno where this should be
		# todo: implement "persistent" skill which allows HP to drop below 0
		if state.character_hp[character] <= 0:
			handle_character_death(character, src_character)
		# if combat hasn't endded due to the death above
		if state:
			state.emit_changed()


## Heal character by given amount up to character's max HP. All healing should
## happen through this method.
##
## todo: ditto as deal_damage
func heal_character(character: GameCharacter, amount: int, src_character: GameCharacter) -> void:
	if active and character in state.character_hp:
		state.character_hp[character] = min(state.character_hp[character] + amount, Ruleset.calculate_max_hp(character))
	_log.system("%s healed %s for %s HP" % [src_character.name, character.name, amount])


## Grant given buff when elligible. Takes care of checking whether combat buff
## is not used outside combat.
func grant_buff(character: GameCharacter, buff: Buff, stack: int = 1) -> void:
	match buff.end_trigger:
		Buff.EndTrigger.COMBAT_TIME when state:
			var onset := BuffOnset.new()
			onset.starting_round = state.round_number
			onset.starting_turn = state.turn_number
			_log.system("%s gained %s" % [character.name, buff.name])
			for _i in range(stack):
				character.add_buff(buff, onset)
		_:
			_log.system("%s gained %s" % [character.name, buff.name])
			character.add_buff(buff)


## Update state when given character's HP falls to 0. May be used also outside
## of combat.
func handle_character_death(character: GameCharacter, killer: GameCharacter = character) -> void:
	# Update combat
	if state:
		var current_active := get_active_character()
		state.remove_participant(character)
		if character == current_active:
			end_turn()
	# Update character resource and controller
	character.alive = false
	var char_ctrl := character.get_controller()
	if character is NpcCharacter:
		char_ctrl.kill_character(killer.position)
		_log.system("%s died" % character.name)
	elif character.get_injuries().size() + 1 == Ruleset.calculate_max_injury_count(character):
		if character is MainCharacter:
			_game_over()
		else:
			char_ctrl.kill_character(killer.position)
			# todo: this will need more work since we need to proparly announce
			# the array changed to all UI etc.
			_game_instance.state.characters.erase(character)
			_log.system("%s met %s ultimate end" % [character.name, character.pronoun])
	elif character is PlayableCharacter:
		char_ctrl.down_character(killer.position)
		_log.system("%s can no longer fight" % character.name)
		# todo: create separate registry that takes care of deciding which injury to use
		var crippling_wound: Buff = load("res://game_resources/buffs/injuries/b_crippling_wound.tres")
		grant_buff(character, crippling_wound)
	# Decide what to do next
	if state:
		if state.pc_participants.size() == 0 or not _game_instance.state.get_mc().alive:
			_game_over()
		elif state.npc_participants.size() == 0:
			_end_combat()
		else:
			combat_participants_changed.emit()


## Update character's action based on its and combat's state.
## All combat action setting should be done through this maybeee??
func update_combat_action(character: GameCharacter) -> void:
	if active:
		var active_chara := get_active_character()
		var pc := character as PlayableCharacter
		var npc := character as NpcCharacter
		if character == active_chara:
			character.action = CharacterCombatReady.new()
		elif pc:
			pc.action = CharacterCombatWaiting.new()
		elif npc and has_npc(npc):
			npc.action = CharacterCombatWaiting.new()
		else:
			character.action = CharacterIdle.new()
	else:
		# post-combat action, should it be handled by combat or explo
		# controller tho?
		var casting := character.action as CharacterCasting
		if casting:
			casting.equeue_action(CharacterIdle.new())
		else:
			character.action = CharacterIdle.new()


var _active_trigger_count: int = 0:
	set(v):
		_active_trigger_count = v
		state.emit_changed()

## Emit given trigger on every character. Second arg can be used to specify
## whom this trigger affects, but it is still emitted to everyone in the
## combat.
func emit_trigger(trigger: EffectTrigger, character: GameCharacter = null) -> EffectTrigger:
	_active_trigger_count += 1
	trigger.character = character
	trigger.combat = self
	for participant in get_participants():
		await participant.emit_trigger(trigger)
	_active_trigger_count -= 1
	return trigger


## Return given character with all its neighbours that shoould join the fight
func _find_npcs_to_add(character: NpcCharacter) -> Array[NpcCharacter]:
	var ctrl := character.get_controller()
	var to_add: Array[NpcCharacter] = []
	var neighbours := ctrl.get_neighbours().map(func (neigbour: NpcController) -> GameCharacter: return neigbour.character)
	# todo: introduce more complex logic for detecting allies of the added character
	var enemy_neighbours := neighbours.filter(func (c: NpcCharacter) -> bool: return c.enemy)
	to_add.assign(enemy_neighbours)
	to_add.push_front(character)
	return to_add


## Add npc participant to (assuming) active combat
func _add_npc(npc: NpcCharacter) -> void:
	state.npc_participants.append(npc)
	update_combat_action(npc)
	_update_initiatives()
	_update_initial_hp()


## Take care of everything connected to combat end that is not a game over.
func _end_combat() -> void:
	for pc in _controlled_characters.get_characters():
		pc.alive = true
	var participants := get_participants()
	for character in participants:
		for key in character.static_buffs:
			var buff := character.static_buffs[key]
			if buff.end_trigger == Buff.EndTrigger.COMBAT_TIME:
				character.static_buffs.erase(key)
	state = null
	for character in participants:
		update_combat_action(character)
	ended.emit()


## Handle switching to game over (or some scripted alternative) screen when all
## character fall during combat.
func _game_over() -> void:
	# todo: everything
	get_tree().quit()


## Calculate inititative for each participant and fill the participant_order
## array accordingly. Can be called again later when new participants were
## added.
func _update_initiatives() -> void:
	var all_chars := state.get_all_participants()
	var message_log := global.message_log()
	for character in all_chars:
		if not state.initiatives.has(character):
			var init_roll := Ruleset.calculate_intitiative(character)
			# Godot's sorting is not stable, so to make it stable we add random
			# number between <0, 0.9> to the integere initivative. This way
			# reruninng the sort with new participants will not change the
			# previous order in case of identical integer intitiatives
			state.initiatives[character] = init_roll.value + randf() / 1.1
			message_log.system("%s rolls initiative: %s" % [character.name, init_roll.text])
	state.update_participant_order()


# Set character's HP to their maximum if they have not HP set yet (= new
# participant)
func _update_initial_hp() -> void:
	for character in state.get_all_participants():
		if not state.character_hp.has(character):
			state.character_hp[character] = Ruleset.calculate_max_hp(character)


# Iterate over all spawned characters and set their action depending on given
# combat state. Should be called at the beginning of the combat to normalize
# all characters, so they stop walking etc.
func _set_default_combat_actions_to_all() -> void:
	var all_npcs := _spawned_npcs.get_characters()
	var all_pcs := _controlled_characters.get_characters()
	for npc in all_npcs:
		update_combat_action(npc)
	for pc in all_pcs:
		update_combat_action(pc)
