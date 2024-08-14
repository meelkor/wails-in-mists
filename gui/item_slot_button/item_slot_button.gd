## Button which may hold single item, displaying its icon and opening its
## tooltip on hover. For use inside inventory, containers etc.
##
## todo: very similar to ability bar button, how to consolidate those two?
extends Control

@export var item: Item:
	set (v):
		item = v
		if _entity_icon:
			_entity_icon.icon = v.icon if v else null

@onready var _entity_icon = %EntityIcon


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_entity_icon.icon = item.icon if item else null


func _on_mouse_entered() -> void:
	_entity_icon.hovered = true
	_open_tooltip()


func _on_mouse_exited() -> void:
	_entity_icon.hovered = false
	_close_tooltip()


func _open_tooltip() -> void:
	var item_tooltip = preload("res://gui/rich_tooltip/item_tooltip/item_tooltip.tscn").instantiate()
	item_tooltip.item = item
	FloatingTooltipSpawner.open_tooltip(self, item_tooltip)


func _close_tooltip() -> void:
	FloatingTooltipSpawner.close_tooltip()
