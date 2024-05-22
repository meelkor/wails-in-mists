# Holds state of current combat (or the information that there is no combat).
# Many nodes expect this node to be provided via DI.
class_name Combat
extends Node

var di = DI.new(self)

@onready var _controlled_characters = di.inject(ControlledCharacters) as ControlledCharacters

@onready var _spawned_npcs = di.inject(SpawnedNpcs) as SpawnedNpcs

## When combat state is defined, the combat is considered as active. All
## information that should be kept when saving the game midcombat should be in
## this combat state instance rather than in this node.
@export var state: CombatState = null

var active: bool:
	get:
		return !!state

# Signal emitted whenever turn (and thus sometimes even round) progresses
signal progressed()

# Signal emitted when combat becomes active or list of participants change in
# active combat
signal combat_participants_changed()

### Public ###

# Announce that given NPC wants to join a combat, collecting its neighbours and either
# activate a new combat or add to existing.
func activate(character: NpcCharacter) -> void:
	var participants = _find_npcs_to_add(character).filter(func (p): return not has_npc(p))
	if participants.size() == 0:
		push_warning("Trying to activate combat with all characters already in")
		return;

	if state:
		for npc in participants:
			_add_npc(npc)
	else:
		# todo: include who was noticed, but currently we are not propagating
		# that information => create some InitCombatData class or whatever.
		global.message_log().system("Your party has been noticed by enemy")
		state = CombatState.new()

		state.pc_participants.assign(_controlled_characters.get_characters())
		state.npc_participants.assign(participants)
		_set_default_combat_actions_to_all()
		_update_initiatives()
		_update_initial_hp()
	combat_participants_changed.emit()

# Get all current participants if the combat is active
func get_participants() -> Array[GameCharacter]:
	if state:
		return state.participant_order
	else:
		return []

func has_npc(npc: NpcCharacter) -> bool:
	return state and state.npc_participants.has(npc)

func get_hp(character: GameCharacter) -> int:
	assert(state, "Cannot get HP when combat not active")
	return state.character_hp[character]

# Get current turn's character
func get_active_character() -> GameCharacter:
	assert(state, "Cannot get active character when combat not active")
	return state.participant_order[state.turn_number]

# Returns false when there is currently some action happening and player
# shouldn't be in any kind of control (e.g. mid-attack, character movement, AI
# turn etc...)
func is_free() -> bool:
	var character = get_active_character()
	return character is PlayableCharacter and character.action is CharacterCombatReady

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
func deal_damage(character: GameCharacter, dmg: int) -> void:
	assert(state, "Cannot deal damage when combat is not active")
	if character is NpcCharacter and not character in state.npc_participants:
		activate(character)

	if state:
		assert(character in state.character_hp, "Affecting character that is not in combat")
		state.character_hp[character] -= dmg
		if dmg >= 0:
			global.message_log().system("%s lost %s HP" % [character.name, dmg])
		else:
			global.message_log().system("%s gained %s HP" % [character.name, dmg])
	else:
		global.message_log().dialogue(character.name, character.hair_color, "[looks slightly annoyed]")

### Private ###

## Return given character with all its neighbours that shoould join the fight
func _find_npcs_to_add(character: NpcCharacter) -> Array[NpcCharacter]:
	var ctrl = _spawned_npcs.get_controller(character)
	var to_add: Array[NpcCharacter] = []
	var neighbours = ctrl.get_neighbours().map(func (neigbour: NpcController): return neigbour.character)
	# todo: introduce more complex logic for detecting allies of the added character
	var enemy_neighbours = neighbours.filter(func (c: NpcCharacter): return c.is_enemy)
	to_add.assign(enemy_neighbours)
	to_add.push_front(character)
	return to_add

## Add npc participant to (assuming) active combat
func _add_npc(npc: NpcCharacter) -> void:
	state.npc_participants.append(npc)
	_update_initiatives()
	_update_initial_hp()

# Calculate inititative for each participant and fill the participant_order
# array accordingly. Can be called again later when new participants were
# added.
func _update_initiatives() -> void:
	var all_chars = state.get_all_participants()
	var message_log = global.message_log()
	for character in all_chars:
		if not state.initiatives.has(character):
			var init_roll = Ruleset.calculate_intitiative(character)
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
	var all_npcs = _spawned_npcs.get_characters()
	var all_pcs = _controlled_characters.get_characters()
	for npc in all_npcs:
		if has_npc(npc):
			npc.action = CharacterCombatWaiting.new()
		else:
			npc.action = CharacterIdle.new()
	for pc in all_pcs:
		pc.action = CharacterCombatWaiting.new()
		pc.selected = false
