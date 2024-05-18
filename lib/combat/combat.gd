# Holds state of current combat (or the information that there is no combat).
# Many nodes expect this node to be provided via DI.
class_name Combat
extends Node

var di = DI.new(self)

@onready var _controlled_characters = di.inject(ControlledCharacters) as ControlledCharacters

@onready var _spawned_npcs = di.inject(SpawnedNpcs) as SpawnedNpcs

# Signal emitted whenever turn (and thus sometimes even round) progresses
signal progressed()

# Signal emitted when combat becomes active or list of participants change in
# active combat
signal combat_participants_changed()

# Round = all participants had their turn
@export var round_number = 0

# Turn number, also works as index in _participant_order array as which
# participant is acting now
@export var turn_number = 0

# Indicates whether the game should be currently in combat mode
@export var active = false

# List of all participants in order decided by their initiative
var _participant_order: Array[GameCharacter] = []

# Dictionary of GameCharacter => int. To get max HP, use the character class
# instead.
var _character_hp: Dictionary = {}

# Array of NPC _npc_participants in this combat
var _npc_participants: Array[NpcCharacter] = []

# Player controlled characters. Combat always involves all characters all
# spawned PlayableCharacters, but storing reference to them in here, makes
# resolving combat logic easier.
var _pc_participants: Array[PlayableCharacter] = []

# Dict GameCharacter => float where the number decides the order in a round.
# _participant_order array is sorted according to this dict. We need to keep it
# stored for the length of the combat in case a new participant is added
var _initiatives: Dictionary = {}

### Public ###

# Announce that given NPC wants to join a combat, collecting its neighbours and either
# activate a new combat or add to existing.
func activate(character: NpcCharacter) -> void:
	var participants = _find_npcs_to_add(character).filter(func (p): return not has_npc(p))
	if participants.size() == 0:
		push_warning("Trying to activate combat with all characters already in")
		return;

	if active:
		for npc in participants:
			_add_npc(npc)
	else:
		# todo: include who was noticed, but currently we are not propagating
		# that information => create some InitCombatData class or whatever.
		global.message_log().system("Your party has been noticed by enemy")

		_pc_participants.assign(_controlled_characters.get_characters())
		_npc_participants.assign(participants)
		_set_default_combat_actions_to_all()
		_update_participant_order()
		_update_initial_hp()
		active = true
	combat_participants_changed.emit()

# Get all current participants if the combat is active
func get_participants() -> Array[GameCharacter]:
	if active:
		return _participant_order
	else:
		return []

func has_npc(npc: NpcCharacter) -> bool:
	return _npc_participants.has(npc)

func get_hp(character: GameCharacter) -> int:
	return _character_hp[character]

# Get current turn's character
func get_active_character() -> GameCharacter:
	return _participant_order[turn_number]

# Returns false when there is currently some action happening and player
# shouldn't be in any kind of control (e.g. mid-attack, character movement, AI
# turn etc...)
func is_free() -> bool:
	var character = get_active_character()
	return character is PlayableCharacter and character.action is CharacterCombatReady

# End current turn, increasing the turn number (or round if this was last turn
# in the round)
func end_turn() -> void:
	if turn_number + 1 == _participant_order.size():
		turn_number = 0
		round_number += 1
	else:
		turn_number += 1
	progressed.emit()

## Deal dmg damage to given character. If the character is not part of current
## combat, add it (and start the combat if it wasn't active until now)
func deal_damage(character: GameCharacter, dmg: int) -> void:
	if character is NpcCharacter and not character in _npc_participants:
		activate(character)

	if active:
		assert(character in _character_hp, "Affecting character that is not in combat")
		_character_hp[character] -= dmg
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
	_npc_participants.append(npc)
	_update_participant_order()
	_update_initial_hp()

func _get_all_participants() -> Array[GameCharacter]:
	var all_chars: Array[GameCharacter] = []
	all_chars.append_array(_npc_participants)
	all_chars.append_array(_pc_participants)
	return all_chars

# Calculate inititative for each participant and fill the _participant_order
# array accordingly. Can be called again later when new participants were
# added.
func _update_participant_order() -> void:
	var all_chars = _get_all_participants()
	var message_log = global.message_log()
	for character in all_chars:
		if not _initiatives.has(character):
			var init_roll = Ruleset.calculate_intitiative(character)
			# Godot's sorting is not stable, so to make it stable we add random
			# number between <0, 0.9> to the integere initivative. This way
			# reruninng the sort with new participants will not change the
			# previous order in case of identical integer intitiatives
			_initiatives[character] = init_roll.value + randf() / 1.1
			message_log.system("%s rolls initiative: %s" % [character.name, init_roll.text])
	all_chars.sort_custom(func (a, b): return true if _initiatives[a] > _initiatives[b] else false)

	var orig_actor: GameCharacter
	if _participant_order.size() > 0:
		orig_actor = _participant_order[turn_number]

	_participant_order = all_chars

	if orig_actor:
		var new_turn_n = _participant_order.find(orig_actor)
		if new_turn_n > -1:
			turn_number = new_turn_n
		else:
			push_warning("Cannot find character which was on turn before updating order")

# Set character's HP to their maximum if they have not HP set yet (= new
# participant)
func _update_initial_hp() -> void:
	for character in _get_all_participants():
		if not _character_hp.has(character):
			_character_hp[character] = Ruleset.calculate_max_hp(character)

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
