## Modifier which grants static bonus to single skill
class_name ModifierSkillBonus
extends Modifier

@export var skill: Skill

@export var amount: int

func add_skill_bonus(_character: GameCharacter, bonus: SkillBonus):
	if bonus.has_skill(skill):
		bonus.add(skill, "shit, modifier needs ref to its parent item", amount)
