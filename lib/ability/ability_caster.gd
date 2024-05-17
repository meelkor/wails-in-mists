# Structure containing all character's abilities which should be provided as
# controller to nodes that may want to display them / cast them
class_name AbilityCaster
extends RefCounted

signal abilities_changed()

var character: GameCharacter

var _combat: Combat

### Lifecycle ###

# combat may be null
func _init(input_character: GameCharacter, combat: Combat):
	character = input_character
	_combat = combat
	character.state_changed.connect(_on_char_state_changed)

### Public ###

func get_buttons():
	var abilities: Array[Ability] = []
	for item in character.equipment.values():
		for modifier in item.modifiers:
			if modifier is ModifierGrantAbility:
				abilities.append(modifier.ability)
	return abilities

### Private ###

func _on_char_state_changed(_c):
	abilities_changed.emit()
