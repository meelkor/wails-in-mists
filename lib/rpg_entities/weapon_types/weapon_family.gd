## Weapon family, level-2 categorization of weapon
class_name WeaponFamily # still do not like the name :((
extends __CombatCategory

## Parent weapon family in the weapon type tree
@export var style: CombatStyle


func get_level() -> int:
	return 2
