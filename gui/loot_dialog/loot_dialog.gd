## Draggable dialog containing items slots the player can pick items from.
##
## The default slots are there only so the control looks representative in the
## editor, but the real slots are created programitacally depending on the
## provided lootable items.
extends MarginContainer


## Reference to the lootable that opened this dialog. Mostly serves as wrapper
## around the list of items, to make sure picked up items disappear from the
## lootable.
@export var lootable: Lootable:
	set(val):
		lootable = val
		if is_inside_tree(): _update_content()

@onready var _item_grid: GridContainer = %ItemGrid


### Lifecycle ###

func _ready() -> void:
	_update_content()


### Private ###

## Updates slots in the dialog based on current lootable (if any)
##
## TODO: reuse slots intead of recreating them
##
## TODO: create some ItemGrid node that will be used in both here and in
## inventory
func _update_content():
	Utils.Nodes.clear_children(_item_grid)
	var slot_count = lootable.slots if lootable.slots != 0 else lootable.items.size()
	var slot_count_rouded = ((slot_count - 1) / _item_grid.columns + 1) * _item_grid.columns
	for slot_i in range(0, slot_count_rouded):
		var btn = preload("res://gui/item_slot_button/item_slot_button.tscn").instantiate()
		btn.disabled = false
		if slot_i < lootable.items.size():
			btn.item = lootable.items[slot_i]
		elif slot_i >= slot_count:
			btn.disabled = true
		_item_grid.add_child(btn)
