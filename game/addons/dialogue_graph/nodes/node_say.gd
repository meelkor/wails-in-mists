## Graph node representing DialogueSay step
@tool
extends DialogueNode

const DialogueSay = preload("res://addons/dialogue_graph/steps/dialogue_say.gd")

@onready var _text_edit := %TextEdit as TextEdit
@onready var _buttons_container := %ButtonsContainer as Control

var _group := ButtonGroup.new()


func get_step() -> DialogueSay:
	return super.get_step()


func _ready() -> void:
	_group.pressed.connect(_button_pressed)
	_text_edit.text = (get_step() as DialogueSay).text
	(_buttons_container.get_child(get_step().actor) as Button).button_pressed = true
	for btn: Button in _buttons_container.get_children():
		btn.toggled.connect(_update_toggle_state.bind(btn))
		btn.button_group = _group
		_update_toggle_state(btn.button_pressed, btn)


func _on_text_edit_text_changed() -> void:
	get_step().text = _text_edit.text


func _update_toggle_state(toggled_on: bool, btn: Button) -> void:
	btn.set_instance_shader_parameter("color", Color("#e8d7e4") if toggled_on else Color("#929292"))


func _button_pressed(button: Button) -> void:
	get_step().actor = _group.get_buttons().find(button) as DialogueSay.DialogueActor
