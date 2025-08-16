@tool
extends DialogueNode

const DialogueBegin = preload("res://addons/dialogue_graph/steps/dialogue_begin.gd")


func get_step() -> DialogueBegin:
	return super.get_step()


func _ready() -> void:
	var begin := get_step()
	(%CheckBoxBlocking as CheckBox).button_pressed = begin.blocking
	(%CheckBoxFocus as CheckBox).button_pressed = begin.focus_actor


func _on_check_box_focus_toggled(toggled_on: bool) -> void:
	get_step().focus_actor = toggled_on


func _on_check_box_blocking_toggled(toggled_on: bool) -> void:
	get_step().blocking = toggled_on
