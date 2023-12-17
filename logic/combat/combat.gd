# Representation of the whole "combat mode". This
class_name Combat
extends RefCounted

# Signal emitted whenever turn (and thus sometimes even round) progresses
signal progressed()

# Round = all participants had their turn
var round_number = 0

# Turn number, also works as index in participant_order array as which
# participant is acting now
var turn_number = 0

# List of all participants in order decided by their initiative
var participant_order: Array[GameCharacter] = []

# Dictionary of GameCharacter => int. To get max HP, use the character class
# instead.
var _character_hp: Dictionary = {}

# Array of NPC _npc_participants in this combat
var _npc_participants: Array[NpcCharacter]

# Player controlled characters. Combat always involves all characters all
# spawned PlayableCharacters, but storing reference to them in here, makes
# resolving combat logic easier.
var _pc_participants: Array[PlayableCharacter]

# Dict GameCharacter => float where the number decides the order in a round.
# participant_order array is sorted according to this dict. We need to keep it
# stored for the length of the combat in case a new participant is added
var _initiatives: Dictionary = {}

### Public ###

func add_npc(npc: NpcCharacter) -> void:
	npc.active_combat = self
	_npc_participants.append(npc)

func has_npc(npc: NpcCharacter) -> bool:
	return _npc_participants.has(npc)

func get_hp(character: GameCharacter) -> int:
	return _character_hp[character]

### Lifecycle ###

func _init(pc_chars: Array[PlayableCharacter], npc_chars: Array[NpcCharacter]):
	_pc_participants = pc_chars
	_npc_participants = npc_chars
	for character in _get_all_participants():
		character.active_combat = self
	_update_participant_order()
	_update_initial_hp()

### Private ###

func _get_all_participants() -> Array[GameCharacter]:
	var all_chars: Array[GameCharacter] = []
	all_chars.append_array(_npc_participants)
	all_chars.append_array(_pc_participants)
	return all_chars

# Calculate inititative for each participant and fill the participant_order
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
	if participant_order.size() > 0:
		orig_actor = participant_order[turn_number]

	participant_order = all_chars

	if orig_actor:
		var new_turn_n = participant_order.find(orig_actor)
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
