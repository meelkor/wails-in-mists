# Structure containing all character's abilities which should be provided as
# controller to nodes that may want to display them / cast them
class_name AbilityCaster
extends RefCounted

signal ability_used(ctrl: AbilityController)

signal abilities_changed()

var _character: GameCharacter

var _combat: Combat

### Public ###

# combat may be null
func _init(character: GameCharacter, combat: Combat):
	_character = character
	_combat = combat
	_character.state_changed.connect(_on_char_state_changed)

func get_buttons():
	var abilities: Array[Ability] = []
	for item in _character._equipment.values():
		for modifier in item.modifiers:
			if modifier is ModifierGrantAbility:
				abilities.append(modifier.ability)
	return abilities

# Return whether ability could be casted (in case of combat, character may no
# longer have actions for that ability)
func cast_ability(ability: Ability) -> Result:
	var result = Result.new()
	var ctrl = AbilityController.new()
	ctrl.caster = _character
	ctrl.ability = ability
	ability_used.emit(ctrl)
	return result

### Private ###

func _on_char_state_changed(_c):
	abilities_changed.emit()

class Result:
	extends RefCounted
	var ok: bool = true
	var message: String
