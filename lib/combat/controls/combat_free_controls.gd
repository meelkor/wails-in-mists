## Controls used in combat when it's player's turn and user is free to take an
## action
class_name CombatFreeControls
extends Node3D

## Number of path vertices supported by the terrain_project_pass shader. Needs
## to match the const defined there as well.
const MAX_PATH_POINTS = 6

var di = DI.new(self)

@onready var _combat: Combat = di.inject(Combat)
@onready var _terrain: TerrainWrapper = di.inject(TerrainWrapper)

### Lifecycle ###

func _ready():
	_terrain.input_event.connect(_on_terrain_input_event)


func _exit_tree() -> void:
	_terrain.project_path_to_terrain(PackedVector3Array())
	_terrain.input_event.disconnect(_on_terrain_input_event)

### Private ###

func _on_terrain_input_event(event: InputEvent, pos: Vector3) -> void:
	var active_char = _combat.get_active_character()
	var available_steps = _combat.get_available_steps()
	if event is InputEventMouseButton:
		if event.is_released() and event.button_index == MOUSE_BUTTON_RIGHT and available_steps > 0:
			var nav_path = _compute_path(active_char.position, pos)
			var sliced_path = Utils.Path.filter_3d_by_2d(nav_path, Utils.Path.path3d_to_path2d(nav_path, MAX_PATH_POINTS))
			var movement = CharacterCombatMovement.new(sliced_path)
			movement.max_length = available_steps
			active_char.action = movement
			_terrain.project_path_to_terrain(nav_path, available_steps)
	elif event is InputEventMouseMotion:
		var path = _compute_path(active_char.position, pos)
		_terrain.project_path_to_terrain(path, available_steps)


## Compute 3D path from one global position to another. Assumes single
## navigation map is used, which will probably be always true in our context.
func _compute_path(from_pos: Vector3, to_pos: Vector3) -> PackedVector3Array:
	var params = NavigationPathQueryParameters3D.new()
	params.map = get_world_3d().get_navigation_map()
	params.start_position = from_pos
	params.target_position = to_pos
	var result = NavigationPathQueryResult3D.new()
	NavigationServer3D.query_path(params, result)
	return result.path

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("end_turn") and not event.echo:
			_combat.end_turn()
