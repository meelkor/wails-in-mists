@tool
extends EditorPlugin

const EditorPanel = preload("res://addons/enumerated_table/editor_panel.tscn")

var editor_panel_scene

func _enter_tree():
	editor_panel_scene = EditorPanel.instantiate()
	EditorInterface.get_editor_main_screen().add_child(editor_panel_scene)
	_make_visible(false)


func _exit_tree():
	if editor_panel_scene:
		editor_panel_scene.queue_free()


func _has_main_screen():
	return true


func _make_visible(visible):
	if editor_panel_scene:
		editor_panel_scene.visible = visible


func _get_plugin_name():
	return "Table Enums"


func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("ItemList", "EditorIcons")
