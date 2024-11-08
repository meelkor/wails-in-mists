# Modifier which grants set ability to character. E.g. basic sword would grant
# ability slash with some parameters
class_name ModifierGrantAbility
extends Modifier

@export var ability: Ability


func get_abilities(_c: GameCharacter, _item: ItemRef) -> Array[AbilityGrant]:
	return [AbilityGrant.new(ability)]
