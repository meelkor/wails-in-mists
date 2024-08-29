class_name PlayerInventory
extends SlotContainer


## Get all equipment that can be assigned to given slot. If -1 is given, all
## equipment is returned.
func get_by_slot(slot: ItemEquipment.Slot) -> Array[Item]:
	var out: Array[Item] = []
	out.assign(_entities.values().filter(func (v): return v is ItemEquipment && (slot == -1 || slot in v.slot)))
	return out


## Completely remove item from the inventory, assuming it currently contains
## this item
func remove_item(_item: Item):
	# todo: rewrite and move to item container
	pass


func get_entity(index: int) -> Item:
	return super.get_entity(index)


func _can_assign(entity: Slottable, _slot_i: int):
	return entity is Item


func _to_string() -> String:
	return "<PlayerInventory#%s>" % get_instance_id()
