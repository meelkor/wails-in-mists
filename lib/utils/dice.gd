class_name Dice
extends Object


static func d20(bonus: SkillBonus = null, dc: int = -1) -> Result:
	return roll(20, bonus, dc)


static func roll(sides: int, bonus: SkillBonus = null, dc: int = -1) -> Result:
	var rolled := randi() % sides + 1
	return Result.new(rolled, bonus, dc)


## Dice roll result with its bonus
class Result:

	## Rolled number
	var roll: int

	## Skill bonus added to the roll
	var _bonus: SkillBonus

	var value: int:
		get: return roll + _bonus.get_total()

	var text: String:
		get: return "%s + %s bonus = %s" % [roll, _bonus.get_total(), value]

	var success: bool = true


	func _init(rolled: int, bonus: SkillBonus = null, dc: int = -1) -> void:
		roll = rolled
		_bonus = bonus if bonus else SkillBonus.new()
		if dc > -1:
			success = roll + _bonus.get_total() >= dc
