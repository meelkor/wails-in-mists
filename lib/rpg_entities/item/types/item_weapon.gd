class_name ItemWeapon
extends ItemEquipment

@export var damage_dice: int


func get_heading() -> String:
	var type_i := modifiers.find(func (mod: Modifier) -> bool: return mod is ModifierWeaponType)
	if type_i >= 0:
		return "Weapon: %s" % (modifiers[type_i] as ModifierWeaponType).type.name
	else:
		return "Weapon"
