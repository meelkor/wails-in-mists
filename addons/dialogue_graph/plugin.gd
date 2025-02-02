## Plugin providing resources for defining branching dialogues with various
## actions and conditions. Also provides new editor tab used to edit Dialogue
## resources in form of graph.
@tool
extends EditorPlugin

const DialogueGraphEditorScene = preload("./dialogue_graph_editor.tscn")
const DialogueGraphEditor = preload("./dialogue_graph_editor.gd")

var _editor_panel_scene: DialogueGraphEditor


func _save_external_data() -> void:
	_editor_panel_scene.save_current_dialogue()


func _enter_tree() -> void:
	_editor_panel_scene = DialogueGraphEditorScene.instantiate()
	EditorInterface.get_editor_main_screen().add_child(_editor_panel_scene)
	_make_visible(false)


func _exit_tree() -> void:
	if _editor_panel_scene:
		_editor_panel_scene.queue_free()


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if _editor_panel_scene:
		_editor_panel_scene.visible = visible


func _get_plugin_name() -> String:
	return "Dialogue"


func _get_plugin_icon() -> Texture2D:
	return load("res://addons/dialogue_graph/resources/question_answer.svg")
