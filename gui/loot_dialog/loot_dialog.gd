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
@onready var _dialog_label: Label = %DialogLabel


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
	_dialog_label.text = lootable.name
	Utils.Nodes.clear_children(_item_grid)
	# bad after change to map
	var slot_count = lootable.slots if lootable.slots != 0 else lootable.items.size()
	var slot_count_rouded = ((slot_count - 1) / _item_grid.columns + 1) * _item_grid.columns
	for slot_i in range(0, slot_count_rouded):
		var btn = preload("res://gui/slot_button/slot_button.tscn").instantiate()
		if slot_i >= slot_count:
			btn.disabled = true
		else:
			btn.used.connect(func (): _handle_slot_use(slot_i))
			btn.slot_i = slot_i
			btn.container = lootable
			btn.disabled = false
		_item_grid.add_child(btn)


## Handle player's usage of the item. I still do not know how to handle quick
## move to inventory vs. equip vs. drink potion or some shit. For now always
## moves to inventory.
func _handle_slot_use(slot_i: int):
	if slot_i < lootable.items.size():
		var item_to_move = lootable.items[slot_i]
		lootable.items.erase(slot_i)
		# todo: check if enough space in inv
		global.player_state().inventory.add_item(item_to_move)
		_update_content()
		if lootable.slots == 0 and lootable.items.size() == 0:
			get_parent().remove_child(self)
			self.queue_free()
