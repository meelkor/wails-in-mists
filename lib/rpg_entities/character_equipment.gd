## SlotContainer is used to represent character's equipment. Should be indexed
## by ItemEquipment.Slot enum
class_name CharacterEquipment
extends SlotContainer


## Get item (or null) currently equipped in given slot
func get_entity(slot: ItemEquipment.Slot) -> ItemEquipment:
	return super.get_entity(slot)


## Helper which returns all equipped items correctly typed
func get_equiped() -> Array[ItemEquipment]:
	var all = super.get_all()
	return all
	# var equips: Array[ItemEquipment] = []
	# equips.assign(_items.values())
	# return equips


## Overriding to ensure only equipments are equippable
func _can_assign(item: Slottable, slot_i: int):
	if item is ItemEquipment:
		return slot_i in item.slot


func _to_string() -> String:
	return "<CharacterEquipment#%s>" % get_instance_id()
