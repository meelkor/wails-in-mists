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
func add_item(item: Item, slot_i: int = -1) -> AssignResult:
	var result = AssignResult.new()
	if item:
		if slot_i == -1:
			slot_i = 0
			while true:
				if not slot_i in items:
					break
				slot_i += 1

		if _can_assign(item, slot_i):
			var old_item = items.get(slot_i, null)
			items[slot_i] = item
			result.item = old_item
			result.ok = true
	else:
		result.item = items.get(slot_i, null)
		items.erase(slot_i)
		result.ok = true

	changed.emit()
	return result


## Can be overriden by subclasses to create picky containers such as character
## equipment container.
func _can_assign(_item: Item, _slot_i: int):
	return true


class AssignResult:
	extends RefCounted

	var item: Item

	var ok: bool = false
