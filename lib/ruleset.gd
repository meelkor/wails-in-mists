## Utility class encapsulating all constants and calculations related to the RPG
## system
class_name Ruleset
extends Object


static func calculate_intitiative(character: GameCharacter) -> Dice.Result:
	return Dice.roll(20, character.get_skill_bonus([Skills.INITIATIVE]))


static func calculate_max_hp(character: GameCharacter) -> int:
	return 4 + character.get_skill_bonus([Skills.HP]).get_total()


## Get all CombatTurn instances the character may take in its turn
static func calculate_turns(character: GameCharacter) -> Array[CombatAction]:
	var out: Array[CombatAction] = [CombatAction.new(null)]
	var tuples := character.attributes.keys().map(func (k: CharacterAttribute) -> Array: return [k, character.attributes[k]])
	tuples.sort_custom(func (a: Array, b: Array) -> float: return a[1] - b[1])

	for tuple: Array in tuples:
		if tuple[1] >= 2:
			out.append(CombatAction.new(tuple[0] as CharacterAttribute))
		if tuple[1] >= 5:
			out.append(CombatAction.new(tuple[0] as CharacterAttribute))

	return out


static func calculate_max_injury_count(character: GameCharacter) -> int:
	@warning_ignore("integer_division")
	return 2 + character.level / 2


## Calcualte how many steps the character may take per single neutral action
## spent
static func calculate_steps_per_action(character: GameCharacter) -> int:
	return 6 + character.get_skill_bonus([Skills.MOVEMENT]).get_total() * 3
