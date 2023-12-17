# Box which displays currently equipped item (item property) with click events
class_name EquipmentSlotBox
extends VBoxContainer

signal select()
signal clear()

@export var slot_name: String

var item: EquipmentItem:
	set (v):
		item = v
		_update_item_label()

func _ready() -> void:
	$SlotLabel.text = slot_name
	$HBoxContainer/SelectEquipmentButton.pressed.connect(func (): select.emit())
	$HBoxContainer/ClearSlotButton.pressed.connect(func (): clear.emit())

func _update_item_label():
	$HBoxContainer/SelectEquipmentButton.text = _get_button_label()

func _get_button_label() -> String:
	return item.name if item else "Select"
