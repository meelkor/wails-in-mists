class_name SkillBonus
extends RefCounted
## Represents set of bonuses for single skill mapped to their various sources,
## so we can then explain how the final number was actually computed.

## Dictionary of skills with their int bonuses mapped to name of their source
## Skill => str => int
var _bonuses: Dictionary = {}

func _init(skills: Array[Skill] = []) -> void:
	for skill in skills:
		_bonuses[skill] = {}

func add(skill: Skill, source: String, bonus: int):
	assert(skill in _bonuses, "Adding bonus for unregistered skill")
	_bonuses[skill][source] = bonus

func get_total() -> int:
	return _bonuses.values().reduce(func (total, skill_bonuses): return total + Math.sum(skill_bonuses.values()), 0)
