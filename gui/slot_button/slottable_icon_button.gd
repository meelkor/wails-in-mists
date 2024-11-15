## Implementation of SlotButton for button with single slot icon
extends SlotButton

@onready var _icon: SlottableIcon = $SlottableIcon


## Update content based on current hover state
func _update_hover(hover: bool) -> void:
	_icon.hovered = hover


## Update content based on currently inserted entity.
func _update_entity(e: Slottable) -> void:
	_icon.icon = e.get_icon() if e else null
	_icon.dimmed = disabled


## Create icon copy to be dragged
func _start_drag() -> Control:
	var dragged_icon := _icon.duplicate() as Control
	_icon.ghost = true
	return dragged_icon


func _end_drag() -> void:
	_icon.ghost = false
