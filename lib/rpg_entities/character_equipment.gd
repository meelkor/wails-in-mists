## ItemContainer is used to represent character's equipment. Should be indexed
## by ItemEquipment.Slot enum
class_name CharacterEquipment
extends ItemContainer


## Get item (or null) currently equipped in given slot
func get_slot(slot: ItemEquipment.Slot) -> ItemEquipment:
	return items.get(slot, null)


## Helper which returns all equipped items correctly typed
func get_all() -> Array[ItemEquipment]:
	var equips: Array[ItemEquipment] = []
	equips.assign(items.values())
	return equips


## Override ItemContainer's can_assign to ensure only equipments are equippable
func _can_assign(item: Item, slot_i: int):
	if item is ItemEquipment:
		return slot_i in item.slot
