## Holds state for the active combat, including participants, HP, current turn
## and its actions...
class_name CombatState
extends Resource

## Round = all participants had their turn
@export var round_number = 0

## Turn number, also works as index in participant_order array as which
## participant is acting now
@export var turn_number = 0

## Dictionary of GameCharacter => int. To get max HP, use the character class
## instead.
@export var character_hp: Dictionary = {}

## Array of NPC _npc_participants in this combat
@export var npc_participants: Array[NpcCharacter] = []

## Player controlled characters. Combat always involves all characters all
## spawned PlayableCharacters, but storing reference to them in here, makes
## resolving combat logic easier.
@export var pc_participants: Array[PlayableCharacter] = []

## Dict GameCharacter => float where the number decides the order in a round.
## participant_order array is sorted according to this dict. We need to keep
## it stored for the length of the combat in case a new participant is added
@export var initiatives: Dictionary = {}

## Computed list of all participants in order decided by their initiative
var participant_order: Array[GameCharacter] = []

### Public ###

func get_all_participants() -> Array[GameCharacter]:
	var all_chars: Array[GameCharacter] = []
	all_chars.append_array(npc_participants)
	all_chars.append_array(pc_participants)
	return all_chars

## Method that needs to be called whenever initiatives change (e.g. new
## character is added)
func update_participant_order() -> void:
	var all_chars = get_all_participants()
	all_chars.sort_custom(func (a, b): return true if initiatives[a] > initiatives[b] else false)

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
