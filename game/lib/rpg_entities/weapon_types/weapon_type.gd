## Weapon type, a level-3 categorization of a weapon
class_name WeaponType
extends __CombatCategory

## Parent weapon family in the weapon type tree
@export var family: WeaponFamily

## Abilities provided when wielding character has proficiency in parent
## CombatStyle.
@export var l1_abilities: Array[Ability]

## Abilities provided when wielding character has proficiency in parent
## WeaponFamily.
@export var l2_abilities: Array[Ability]

## Abilities provided when wielding character has proficiency this exact weapon
## type.
@export var l3_abilities: Array[Ability]


func get_level() -> int:
	return 3
