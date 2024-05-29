# Utility class encapsulating all constants and calculations related to the RPG
# system
class_name Ruleset
extends Object

static func calculate_intitiative(character: GameCharacter) -> Dice.Result:
	return Dice.roll(20, character.get_skill_bonus([Skills.INITIATIVE]))

static func calculate_max_hp(character: GameCharacter) -> int:
	return character.get_skill_bonus([Skills.HP]).get_total()
