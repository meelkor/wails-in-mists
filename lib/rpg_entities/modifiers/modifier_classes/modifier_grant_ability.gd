## Modifier which grants set ability to character.
class_name ModifierGrantAbility
extends Modifier

@export var ability: Ability


func get_abilities(_c: GameCharacter, _source: ModifierSource) -> Array[AbilityGrant]:
	return [AbilityGrant.new(ability)]


func get_label() -> String:
	return "Grant %s" % ability.name
