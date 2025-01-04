## Modifier which grants static bonus to single skill
class_name ModifierSkillBonus
extends Modifier

@export var skill: Skill

@export var amount: int


func add_skill_bonus(_character: GameCharacter, bonus: SkillBonus, source: ModifierSource) -> void:
	if bonus.has_skill(skill):
		bonus.add(skill, source.name, amount)


func get_label() -> String:
	return "%s bonus" % skill.name


func get_description() -> String:
	return "%s +%s" % [skill.name, amount]
