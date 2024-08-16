class_name ItemArmor
extends ItemEquipment

@export var base_defense_bonus: int

func _init() -> void:
	slot = [ItemEquipment.Slot.ARMOR]
