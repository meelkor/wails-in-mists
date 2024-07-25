@tool
extends Control

# todo: decide whether slots will be limites
const INVENTORY_SLOT_COUNT = 8 * 6 # 8 = _grid cols

var di = DI.new(self)

@onready var level_gui: LevelGui = di.inject(LevelGui)

@onready var _grid: GridContainer = %InventoryGrid

@onready var _inventory = global.player_state().inventory

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for _i in range(0, INVENTORY_SLOT_COUNT):
		_grid.add_child(preload("res://gui/item_slot_button/item_slot_button.tscn").instantiate())
	_update_inventory()


func _update_inventory() -> void:
	for slot_i in range(0, _inventory.items.size()):
		var item: Item = _inventory.items[slot_i]
		var btn = _grid.get_child(slot_i)
		btn.text = "test";
		btn.icon = item.icon
	for slot_i in range(_inventory.items.size(), _grid.get_child_count()):
		var btn = _grid.get_child(slot_i)
		btn.text = "";


func _on_close_button_pressed() -> void:
	level_gui.close_inventory()
