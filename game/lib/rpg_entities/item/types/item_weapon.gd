@tool
class_name ItemWeapon
extends ItemEquipment

## If 0, the damage dice is omitted from tooltip and no weapon's abilities
## should be refence it for computing their effect
@export var damage_dice: int = 0

## Base reach each skill may or may not use to calculate their reach
@export var reach: float = 1


func get_heading() -> String:
	var type_i := modifiers.find(func (mod: Modifier) -> bool: return mod is ModifierWeaponType)
	if type_i >= 0:
		return "Weapon: %s" % (modifiers[type_i] as ModifierWeaponType).type.name
	else:
		return "Weapon"
