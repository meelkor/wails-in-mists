## Represents set of bonuses for single skill mapped to their various sources,
## so we can then explain how the final number was actually computed.
class_name SkillBonus
extends RefCounted

## Dictionary of skills with their int bonuses mapped to name of their source
## Skill => str => int
var _bonuses: Dictionary[Skill, Dictionary] = {}


func _init(skills: Array[Skill] = []) -> void:
	for skill in skills:
		_bonuses[skill] = {}


func add(skill: Skill, source: String, bonus: int) -> void:
	assert(skill in _bonuses, "Adding bonus for unregistered skill")
	_bonuses[skill][source] = bonus


func has_skill(skill: Skill) -> bool:
	return skill in _bonuses


func get_total() -> int:
	return _bonuses.values().reduce(func (total: int, skill_bonuses: Dictionary) -> int: return total + Math.sumi(skill_bonuses.values()), 0)
