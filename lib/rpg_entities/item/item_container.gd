## Should be used for any structure containing items like Inventory, Lootables
## but even Equipment slots, so the access is unified for drag and dropping and
## item slot button.
class_name ItemContainer
extends Resource

## int => Item, changes from outside should not be made directly, but via some
## of the ItemContainer methods
@export var items: Dictionary


## Add given item on given index, or on the first empty slot in the map if no
## slot given. Returns item if the action replaced item. Otherwise null. If
## null given instead of item, the slot is removed.
func add_item(item: Item, slot_i: int = -1) -> Item:
	if item:
		if slot_i == -1:
			slot_i = 0
			while true:
				if not slot_i in items:
					items[slot_i] = item
					break
				slot_i += 1
		else:
			var old_item = items.get(slot_i, null)
			items[slot_i] = item
			return old_item
	else:
		items.erase(slot_i)
	changed.emit()
	return null
