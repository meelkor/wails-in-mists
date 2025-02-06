@tool
extends DialogueNode

const DialogueBegin = preload("res://addons/dialogue_graph/steps/dialogue_begin.gd")


func _ready() -> void:
	var begin := step as DialogueBegin
	(%CheckBoxBlocking as CheckBox).button_pressed = begin.blocking
	(%CheckBoxFocus as CheckBox).button_pressed = begin.focus_actor


func _on_check_box_focus_toggled(toggled_on: bool) -> void:
	(step as DialogueBegin).focus_actor = toggled_on


func _on_check_box_blocking_toggled(toggled_on: bool) -> void:
	(step as DialogueBegin).blocking = toggled_on
