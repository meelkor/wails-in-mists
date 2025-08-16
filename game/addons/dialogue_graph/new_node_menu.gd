## Scene which lists all available Step types used when adding new step in the
## editor.
@tool
extends PanelContainer

## todo: maybe scap the steps/ directory instead of hardcoding them
const BUTTONS: Dictionary[String, GDScript] = {
	"Character Say": preload("res://addons/dialogue_graph/steps/dialogue_say.gd"),
	"Begin": preload("res://addons/dialogue_graph/steps/dialogue_begin.gd"),
}

signal step_selected(v: __DialogueStep)

@onready var _buttons_container := %ButtonsContainer as VBoxContainer


func _ready() -> void:
	for label in BUTTONS:
		var Class := BUTTONS[label]
		var button := Button.new()
		button.name = label
		button.text = label
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func () -> void: step_selected.emit(Class.new()))
		_buttons_container.add_child(button)
