## Modifier which grants static bonus to single skill
class_name ModifierSkillBonus
extends Modifier

@export var skill: Skill

@export var amount: int

func add_skill_bonus(_character: GameCharacter, bonus: SkillBonus) -> void:
	if bonus.has_skill(skill):
		bonus.add(skill, "shit, modifier needs ref to its parent item", amount)


func get_label() -> String:
	return "%s +%s" % [skill.name, amount]
