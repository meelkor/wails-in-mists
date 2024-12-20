## Controls used in combat when it's player's turn and user is free to take an
## action
class_name CombatFreeControls
extends Node3D

## Number of path vertices supported by the terrain_project_pass shader. Needs
## to match the const defined there as well.
const MAX_PATH_POINTS = 6

var di := DI.new(self)

@onready var _combat: Combat = di.inject(Combat)
@onready var _terrain: Terrain = di.inject(Terrain)
@onready var _navigation: Navigation = di.inject(Navigation)


func _ready() -> void:
	_terrain.input_event.connect(_on_terrain_input_event)


func _exit_tree() -> void:
	_terrain.project_path_to_terrain(PackedVector3Array())
	_terrain.input_event.disconnect(_on_terrain_input_event)


func _on_terrain_input_event(event: InputEvent, pos: Vector3) -> void:
	if not _combat.active:
		return
	var active_char := _combat.get_active_character()
	var available_steps := _combat.get_available_steps()
	var btn_event := event as InputEventMouseButton
	var motion_event := event as InputEventMouseMotion
	var navigable := _navigation.is_navigable(pos)
	if btn_event and navigable:
		if btn_event.is_released() and btn_event.button_index == MOUSE_BUTTON_LEFT and available_steps > 0:
			var nav_path := _compute_path(active_char.position, pos)
			# var sliced_path := Utils.Path.filter_3d_by_2d(nav_path, Utils.Path.path3d_to_path2d(nav_path, MAX_PATH_POINTS))
			# ^ was this actually needed?
			var movement := CharacterCombatMovement.new(nav_path)
			movement.max_length = available_steps
			active_char.action = movement
	elif motion_event and active_char.is_free():
		if navigable:
			var path := _compute_path(active_char.position, pos)
			_terrain.project_path_to_terrain(path, available_steps)
			GameCursor.use_default()
		else:
			_terrain.project_path_to_terrain([])
			GameCursor.use_ng()


## Compute 3D path from one global position to another. Assumes single
## navigation map is used, which will probably be always true in our context.
func _compute_path(from_pos: Vector3, to_pos: Vector3) -> PackedVector3Array:
	var params := NavigationPathQueryParameters3D.new()
	params.map = _navigation.get_navigation_map()
	params.start_position = from_pos
	params.target_position = to_pos
	var result := NavigationPathQueryResult3D.new()
	NavigationServer3D.query_path(params, result)
	return result.path


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event:
		if key_event.is_action_pressed("end_turn") and not key_event.echo:
			_combat.end_turn()
