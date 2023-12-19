class_name ItemSelectionSubdialog
extends Control

signal selected(item: Item)

# Class by which inventory items should be filtered
var equipment_slot_filter: int = -1

func _ready():
	var box = (%ItemsHolder as VBoxContainer)
	var inv = global.player_state().inventory
	var items = inv.get_by_slot(equipment_slot_filter)
	for item in items:
		var btn = Button.new()
		btn.text = item.name
		btn.pressed.connect(func (): selected.emit(item))
		box.add_child(btn)
