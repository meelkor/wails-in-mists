class_name Dice
extends Object

static func roll(sides: int, bonus: SkillBonus) -> Result:
	var rolled = randi() % sides + 1
	return Result.new(rolled, bonus if bonus else SkillBonus.new())

# Dice roll result with its bonus
class Result:

	# Rolled number
	var _rolled: int

	# Skill bonus added to the roll
	var _bonus: SkillBonus

	var value: int:
		get: return _rolled + _bonus.get_total()

	var text: String:
		get: return "%s + %s bonus = %s" % [_rolled, _bonus.get_total(), value]

	func _init(rolled: int, bonus: SkillBonus):
		_rolled = rolled
		_bonus = bonus
