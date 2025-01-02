class_name ItemWeapon
extends ItemEquipment

@export var damage_dice: int

@export var type: WeaponMeta.TypeL3Id


func get_heading() -> String:
	return "Weapon: %s" % WeaponMeta.get_l3_type(type).name
