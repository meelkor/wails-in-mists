# Defines behaviour (usually boon) in which way the modified entity affects
# character. Modifiers are expected to be used with items.
class_name Modifier
extends Resource

@export var well_known: bool = false

## Optional method which may be implemented by the modifier
func add_skill_bonus(_character: GameCharacter, _skill_bonus: SkillBonus) -> void:
	pass


## Optional method to grant abilities to character which may be implemented by
## the modifier
func get_abilities(_character: GameCharacter, _item: ItemRef) -> Array[AbilityGrant]:
	return []


## Optional method which may be implemented by the modifier
func get_label() -> String:
	return ""
