@tool
extends Control

# todo: decide whether slots will be limites
const INVENTORY_SLOT_COUNT = 8 * 6 # 8 = _grid cols

var di := DI.new(self)

@onready var level_gui: LevelGui = di.inject(LevelGui)

@onready var _grid: GridContainer = %InventoryGrid

@onready var _inventory := global.player_state().inventory

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(0, INVENTORY_SLOT_COUNT):
		var item_btn := preload("res://gui/slot_button/slot_button.tscn").instantiate() as SlotButton
		item_btn.container = _inventory
		item_btn.slot_i = i
		item_btn.use_on_doubleclick = true
		_grid.add_child(item_btn)


func _on_close_button_pressed() -> void:
	level_gui.close_inventory()
