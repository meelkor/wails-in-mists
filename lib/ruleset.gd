## Utility class encapsulating all constants and calculations related to the RPG
## system
class_name Ruleset
extends Object

static func calculate_intitiative(character: GameCharacter) -> Dice.Result:
	return Dice.roll(20, character.get_skill_bonus([Skills.INITIATIVE]))

static func calculate_max_hp(character: GameCharacter) -> int:
	return character.get_skill_bonus([Skills.HP]).get_total()


## Get all CombatTurn instances the character may take in its turn
static func calculate_turns(character: GameCharacter) -> Array[CombatAction]:
	var out: Array[CombatAction] = [CombatAction.new(null)]
	var tuples = character.attributes.keys().map(func (k): return [k, character.attributes[k]])
	tuples.sort_custom(func (a, b): return a[1] - b[1])

	for tuple in tuples:
		if tuple[1] >= 2:
			out.append(CombatAction.new(tuple[0]))
		if tuple[1] >= 5:
			out.append(CombatAction.new(tuple[0]))

	return out


## Calcualte how many steps the character may take per single neutral action
## spent
static func calculate_steps_per_action(character: GameCharacter) -> int:
	return 10 + character.get_skill_bonus([Skills.MOVEMENT]).get_total() * 3
