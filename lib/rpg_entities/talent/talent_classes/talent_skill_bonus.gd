## Talent which simply gives bonus to some skill (may be multiplied by
## attribute if specified)
class_name TalentSkillBonus
extends Talent

## Skill to grant bonus to
@export var skill: Skill

## Granted bonus amount
@export var amount: int

## Optional attribute whose value multiplies the skill bonus
@export var attribute: CharacterAttribute


func name() -> String:
	return "%s bonus" % skill.name


func add_skill_bonus(_char: GameCharacter, bonus: SkillBonus) -> void:
	if bonus.has_skill(skill):
		bonus.add(skill, name(), amount)
