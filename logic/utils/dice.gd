class_name Dice
extends Object

static func roll(sides: int, bonus: int  = 0) -> Result:
	var rolled = randi() % sides + 1
	return Result.new(rolled, bonus)

# Dice roll result with its bonus
class Result:

	# Rolled number
	var _rolled: int

	# Static bonus added to the rooll
	var _bonus: int

	var value: int:
		get: return _rolled + _bonus

	var text: String:
		get: return "%s + %s bonus = %s" % [_rolled, _bonus, value]

	func _init(rolled: int, bonus: int):
		_rolled = rolled
		_bonus = bonus
