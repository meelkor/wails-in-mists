## Holds state of current combat (or the information that there is no combat).
## Many nodes expect this node to be provided via DI.
class_name Combat
extends Node

var di := DI.new(self)

@onready var _controlled_characters := di.inject(ControlledCharacters) as ControlledCharacters

@onready var _spawned_npcs := di.inject(SpawnedNpcs) as SpawnedNpcs

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

### Public ###

## Announce that given NPC wants to join a combat, collecting its neighbours
## and either activate a new combat or add to existing.
##
## When skip_signals is true, the game won't actually react to the combat
## starting.
func activate(character: NpcCharacter, skip_signals: bool = false) -> void:
	var participants := _find_npcs_to_add(character).filter(func (p: NpcCharacter) -> bool: return not has_npc(p))
	if participants.size() == 0:
		push_warning("Trying to activate combat with all characters already in")
		return;

	if state:
		for npc: NpcCharacter in participants:
			_add_npc(npc)
	else:
		# todo: include who was noticed, but currently we are not propagating
		# that information => create some InitCombatData class or whatever.
		global.message_log().system("Your party has been noticed by enemy")
		state = CombatState.new()

		state.pc_participants.assign(_controlled_characters.get_characters())
		state.npc_participants.assign(participants)
		_update_initiatives()
		_update_initial_hp()

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
	if active:
		var character := get_active_character()
		return character is PlayableCharacter and character.action is CharacterCombatReady
	else:
		return false


# End current turn, increasing the turn number (or round if this was last turn
# in the round)
func end_turn() -> void:
	assert(state, "Cannot end turn when combat is not active")
	if state.turn_number + 1 == state.participant_order.size():
		state.turn_number = 0
		state.round_number += 1
	else:
		state.turn_number += 1
	progressed.emit()


## Deal dmg damage to given character. If the character is not part of current
## combat, add it (and start the combat if it wasn't active until now)
##
## todo: wrap dmg with more info about it (including the source chara/ability)
## into some structure.
func deal_damage(character: GameCharacter, dmg: int, src_character: GameCharacter = character) -> void:
	var npc := character as NpcCharacter
	var pc := character as PlayableCharacter
	var owes_signals := false

	if not state:
		if pc:
			global.message_log().dialogue(character.name, character.hair_color, "[looks disappointed]")
			# todo: properly implement "try save against some skill or add
			# injury, dc should be based on dmg vs max hp ratio?"
			return
		elif npc:
			npc.is_enemy = true
			activate(npc, true)
			owes_signals = true

	if state:
		if npc and not npc in state.npc_participants:
			activate(npc)
		assert(character in state.character_hp, "Affecting character that is not in combat")
		state.character_hp[character] -= dmg
		if dmg >= 0:
			global.message_log().system("%s lost %s HP" % [character.name, dmg])
		else:
			global.message_log().system("%s gained %s HP" % [character.name, dmg])
		# todo: still dunno where this should be
		# todo: implement "persistent" skill which allows HP to drop below 0
		if state.character_hp[character] <= 0:
			handle_character_death(character, src_character)

	# Do not start combat when the initiator died while initiating combat and
	# there is no one else to fight.
	if owes_signals and state.npc_participants.size() > 0:
		combat_participants_changed.emit()


## Update state when given character's HP falls to 0
func handle_character_death(character: GameCharacter, killer: GameCharacter = character) -> void:
	var current_active := get_active_character()
	state.remove_participant(character)
	if character == current_active:
		end_turn()
	character.alive = false
	character.died_in_combat.emit(killer.position)
	if character is PlayableCharacter:
		pass
		# add injury based on damage type which is currently not propagated
		# here. if number of injuries higher than 2 + floor(lvl/2)
	if state.pc_participants.size() == 0:
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
		# in case combat ended during some operation such as ability casting
		character.action = CharacterIdle.new()


## Return given character with all its neighbours that shoould join the fight
func _find_npcs_to_add(character: NpcCharacter) -> Array[NpcCharacter]:
	var ctrl := character.get_controller()
	var to_add: Array[NpcCharacter] = []
	var neighbours := ctrl.get_neighbours().map(func (neigbour: NpcController) -> GameCharacter: return neigbour.character)
	# todo: introduce more complex logic for detecting allies of the added character
	var enemy_neighbours := neighbours.filter(func (c: NpcCharacter) -> bool: return c.is_enemy)
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
	state = null
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
