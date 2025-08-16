@tool
extends Control

# todo: decide whether slots will be limites
const INVENTORY_SLOT_COUNT = 8 * 6 # 8 = _grid cols

var di := DI.new(self)

@onready var _level_gui: LevelGui = di.inject(LevelGui)
@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)

@onready var _grid: GridContainer = %InventoryGrid

@onready var _game_instance: GameInstance = di.inject(GameInstance)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(0, INVENTORY_SLOT_COUNT):
		var item_btn := preload("res://gui/slot_button/slottable_icon_button.tscn").instantiate() as SlotButton
		item_btn.container = _game_instance.state.inventory
		item_btn.slot_i = i
		item_btn.use_on_doubleclick = true
		_grid.add_child(item_btn)
		item_btn.used.connect(_on_item_used.bind(i))


func _on_close_button_pressed() -> void:
	_level_gui.close_inventory()


func _on_item_used(slot_i: int) -> void:
	var item_ref := _game_instance.state.inventory.get_entity(slot_i) as ItemRef
	var stack_ref := item_ref as StackRef
	if item_ref:
		var consumable := item_ref.item as ItemConsumable
		var eq := item_ref.item as ItemEquipment
		var main_pc := _controlled_characters.get_selected_main()
		if eq:
			if _level_gui._open_dialog_char:
				var equipment := _level_gui._open_dialog_char.equipment
				var dst_slot := equipment.get_available_slot(item_ref)
				_game_instance.state.inventory.move_entity(equipment, slot_i, dst_slot)
		if consumable and main_pc:
			@warning_ignore("redundant_await")
			var decrement := await consumable.on_use(main_pc)
			if decrement:
				if stack_ref and stack_ref.count > 1:
					stack_ref.count -= 1
				else:
					_game_instance.state.inventory.erase(slot_i)
