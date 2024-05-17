class_name TalentScript
extends Object

# Static method the talent script may implement to grant bonus (possibly
# negative) to selected skills. The bonus may depend on some information about
# the character and thus has the whole GameCharacter instance available.
static func skill_bonus(_char: GameCharacter, _skill: Skill) -> int:
	return 0
