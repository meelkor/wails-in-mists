## Main editor screen's new tab for loading and editing Dialogue resources
@tool
extends Control

const NewNodeMenu := preload("res://addons/dialogue_graph/new_node_menu.gd")

## List of last cut/copied steps used for manual copy/pasting
static var clipboard: Array[__DialogueStep]

## Currently edited dialogue
var dialogue: DialogueGraph:
	set(v):
		if dialogue:
			for step in dialogue.steps:
				# todo: it should always be connected, but for some reason it's
				# not, dunno what's going on here :(
				if step.changed.is_connected(_mark_as_modified):
					step.changed.disconnect(_mark_as_modified)
		dialogue = v
		_update_content()


var _next_node_position: Vector2

var _picker: EditorResourcePicker

var _file_dialog: EditorFileDialog

var _modified: bool = false:
	set(v):
		_modified = v
		if _file_label:
			_file_label.visible = v

@onready var _graph := %GraphEdit as GraphEdit
@onready var _new_node_menu := %NewNodeMenu as NewNodeMenu
@onready var _top_containter := %TopContainer as HBoxContainer
@onready var _graph_container := %GraphContainer as Control
@onready var _file_label := %FileLabel as Label


## Save currently edited dialogue. Open file save dialog if the resource has no
## path.
func save_current_dialogue() -> void:
	if not dialogue.resource_path:
		_file_dialog.popup()
		var path := await _file_dialog.file_selected as String
		dialogue.resource_path = path
	_file_label.visible = false
	ResourceSaver.save(dialogue)


func _ready() -> void:
	_file_dialog = _create_file_dialog()
	add_child(_file_dialog)
	_picker = EditorResourcePicker.new()
	_picker.name = "EditorResourcePicker"
	_picker.custom_minimum_size.x = 260
	_picker.base_type = "DialogueGraph"
	_picker.resource_changed.connect(_on_resource_picked)
	_top_containter.add_child(_picker)


func _create_file_dialog() -> EditorFileDialog:
	var dialog := EditorFileDialog.new()
	dialog.filters.append("*.tres")
	dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialog.access = EditorFileDialog.ACCESS_RESOURCES
	dialog.title = "Create a new dialogue"
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	return dialog


func _on_resource_picked(v: DialogueGraph) -> void:
	dialogue = v


## Clear graph and create all nodes according to the current dialogue
func _update_content() -> void:
	for child in _graph.find_children("", "DialogueNode", false, false):
		prints("removing", child)
		_graph.remove_child(child)
		child.queue_free()
	_graph_container.visible = dialogue != null
	if dialogue:
		for step in dialogue.steps:
			_add_step_node(step)


## Create graph node for given step and add it into the graph. Assumes the step
## is already in the dialogue resource.
func _add_step_node(step: __DialogueStep) -> void:
	var new_node := step.make_node()
	prints("create", new_node)
	_graph.add_child(new_node)
	for i in range(step.source_names.size()):
		_graph.connect_node(step.source_names[i], step.source_ports[i], step.id, 0)
	if step.is_connected("changed", _mark_as_modified):
		push_warning("ResourceSaver already connected, signal connections not correctly cleaned up?")
	else:
		step.changed.connect(_mark_as_modified)


func _mark_as_modified() -> void:
	_modified = true


func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_graph.connect_node(from_node, from_port, to_node, to_port)
	var step := dialogue.find_step(to_node)
	step.source_names.append(from_node)
	step.source_ports.append(from_port)
	_mark_as_modified()


func _on_graph_edit_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_graph.disconnect_node(from_node, from_port, to_node, to_port)
	var step := dialogue.find_step(to_node)
	var i := step.source_names.find(from_node)
	step.source_names.remove_at(i)
	step.source_ports.remove_at(i)
	_mark_as_modified()


func _get_id(prefix: String = "S") -> String:
	if dialogue:
		var id := prefix + str(dialogue.iterator)
		dialogue.iterator += 1
		return id
	else:
		push_warning("Making ID without dialogue with iterator")
		return "n/a"


## Show the step type menu and store the clicked position so we create the node
## there once user selects it.
func _on_graph_edit_popup_request(at_position: Vector2) -> void:
	_new_node_menu.visible = true
	_next_node_position = at_position
	_new_node_menu.position = at_position


func _on_new_node_menu_step_selected(step: __DialogueStep) -> void:
	step.id = _get_id()
	_new_node_menu.visible = false
	var graph_pos := (_graph.scroll_offset + _next_node_position) / _graph.zoom
	step.position = (graph_pos / 20).round() * 20
	_add_step(step)


## Add step to the currently edited dialogue and show its node in the graph.
func _add_step(step: __DialogueStep) -> void:
	if dialogue:
		dialogue.steps.append(step)
		_add_step_node(step)
		_mark_as_modified()


func _gui_input(event: InputEvent) -> void:
	var btn := event as InputEventMouseButton
	if btn and btn.pressed and btn.button_index == MOUSE_BUTTON_LEFT:
		_new_node_menu.visible = false


func _on_graph_edit_delete_nodes_request(step_ids: Array[StringName]) -> void:
	for id in step_ids:
		_remove_from_dialogue(id)


func _on_graph_edit_end_node_move() -> void:
	for child: GraphNode in _graph.find_children("", "GraphNode", false, false):
		if child.selected:
			dialogue.find_step(child.name).position = child.position_offset


func _get_selected_steps() -> Array[__DialogueStep]:
	var out: Array[__DialogueStep]
	var arr := _graph.find_children("", "DialogueNode", false, false)\
		.filter(func (n: DialogueNode) -> bool: return n.selected)\
		.map(func (n: DialogueNode) -> __DialogueStep: return n.step)
	out.assign(arr)
	return out


func _on_graph_edit_paste_nodes_request() -> void:
	for step in clipboard:
		var copy := _duplicate_step(step)
		copy.position += Vector2(40, 40)
		_add_step(copy)


func _on_graph_edit_cut_nodes_request() -> void:
	clipboard.assign(_get_selected_steps())
	for step in _get_selected_steps():
		_remove_from_dialogue(step.id)


## Remove step with given ID from currently edited dialogue and remove its node
## from graph.
func _remove_from_dialogue(id: String) -> void:
	if dialogue:
		dialogue.delete_step(id)
		_graph.remove_child(_graph.get_node(NodePath(id)))
		_mark_as_modified()


func _on_graph_edit_copy_nodes_request() -> void:
	clipboard.assign(_get_selected_steps())


## Create unrelated disconnected copy of given step
func _duplicate_step(step: __DialogueStep) -> __DialogueStep:
	var new_step := step.duplicate() as __DialogueStep
	new_step.id = _get_id()
	new_step.source_names = []
	new_step.source_ports = []
	return new_step
