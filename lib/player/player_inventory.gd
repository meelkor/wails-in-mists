extends Object
class_name PlayerInventory

var items: Array[Item] = []

signal changed()

# Get all equipment that can be assigned to given slot. If -1 is given, all
# equipment is returned.
func get_by_slot(slot: ItemEquipment.Slot) -> Array[Item]:
	return items.filter(func (v): return v is ItemEquipment && (slot == -1 || slot in v.slot))

# Completely remove item from the inventory, assuming it currently contains
# this item
func remove_item(item: Item):
	items.erase(item)

# Add new item testing it's not already in the inventory
func add_item(item: Item):
	if not item in items:
		items.append(item)
