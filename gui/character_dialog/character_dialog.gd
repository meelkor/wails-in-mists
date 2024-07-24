extends BoxContainer
class_name CharacterDialog

@onready var select_armor_btn = %ArmorSlotBox as EquipmentSlotBox
@onready var select_main_hand_btn = %MainHandSlotBox as EquipmentSlotBox
@onready var select_off_hand_btn = %OffHandSlotBox as EquipmentSlotBox
@onready var select_accessory_btn = %AccessorySlotBox as EquipmentSlotBox

# Signal emitted when the dialog wants to be closed
signal close()

var _character: PlayableCharacter

# EquipmentSlotBox nodes mapped to their respective EquipmentSlots
var _mapped_buttons: Dictionary = {}

var _subdialog: Control

func _ready():
	_mapped_buttons = {
		ItemEquipment.Slot.ARMOR: select_armor_btn,
		ItemEquipment.Slot.MAIN: select_main_hand_btn,
		ItemEquipment.Slot.OFF: select_off_hand_btn,
		ItemEquipment.Slot.ACCESSORY: select_accessory_btn,
	}
	_update_dialog_contents()
	_register_equipment_btn_handler()
	_character.state_changed.connect(func (_c): _update_dialog_contents())

# Set inputs, should be called before adding node to tree
func setup(character: PlayableCharacter):
	_character = character

# Update name, equipment button etc
func _update_dialog_contents():
	(%CharacterNameLabel as Label).text = _character.name
	for slot in _mapped_buttons:
		var btn = _mapped_buttons[slot]
		btn.item = _character.equipment.from_slot(slot)

# Handle equipment selection buttons
func _register_equipment_btn_handler():
	for slot in _mapped_buttons:
		var btn = _mapped_buttons[slot]
		btn.select.connect(func (): _open_equipment_selection(slot))
		btn.clear.connect(func (): _remove_item_from_slot(slot))

# Open weapon selection dialog for given slot and assign to the slot selected
# equipment
func _open_equipment_selection(slot: ItemEquipment.Slot):
	_close_subdialog()
	var SubdialogScene = preload("res://gui/item_selection_subdialog/item_selection_subdialog.tscn")
	_subdialog = SubdialogScene.instantiate() as ItemSelectionSubdialog
	_subdialog.equipment_slot_filter = slot
	add_child(_subdialog)
	var item = await _subdialog.selected
	var inventory = global.player_state().inventory
	# TODO: some global utility should be introduced for this
	var prev_item = _character.equipment.equip(slot, item)
	inventory.remove_item(item)
	if prev_item:
		inventory.add_item(prev_item)
	_close_subdialog()

# Remove item from given slot and return it to inventory
func _remove_item_from_slot(slot: ItemEquipment.Slot):
	var prev_item = _character.equipment.unequip(slot)
	if prev_item:
		global.player_state().inventory.add_item(prev_item)


# Escape handler
func _input(event: InputEvent) -> void:
	if event.is_action("dialog_close"):
		close.emit()

func _close_subdialog():
	if _subdialog:
		remove_child(_subdialog)
