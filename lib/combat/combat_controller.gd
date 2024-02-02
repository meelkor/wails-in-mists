# Node which should be created by level during the combat with all required
# public properties set. Takes care of character movement, actions etc. during
# the player's turn.
#
# Note that once this node is added to the tree it starts progressing the
# combat by itself.
class_name CombatController
extends Node3D

var di = DI.new(self)

@onready var _terrain: TerrainWrapper = di.inject(TerrainWrapper)
@onready var _combat: Combat = di.inject(Combat)

# Number of path vertices supported by the terrain_project_pass shader. Needs
# to match the const defined there as well.
const MAX_PATH_POINTS = 6

### Lifecycle ###

func _ready() -> void:
	_terrain.input_event.connect(_on_terrain_input_event)
	_start_combat_turn()

### Private ###

# Run logic related to combat turn, setting the active character's action,
# running AI if NPC etc.
func _start_combat_turn() -> void:
	var character = _combat.get_active_character()
	global.message_log().system("%s's turn" % character.name)
	# todo: implement some animated move_to (ease_to) and use that instead
	get_viewport().get_camera_3d().move_to(character.position)
	# todo: somewhere we need to change the action again at the end of the turn
	if character is PlayableCharacter:
		character.action = CharacterCombatReady.new()
	# todo: this signal should be probably "turn end requested" and turn end
	# should be handled afterward
	await _combat.progressed
	if _combat.active and is_inside_tree():
		_start_combat_turn()

func _on_terrain_input_event(event: InputEvent, pos: Vector3) -> void:
	var active_char = _combat.get_active_character()
	if active_char is PlayableCharacter and _combat.is_free():
		if event is InputEventMouseButton:
			if event.is_released() and event.button_index == MOUSE_BUTTON_RIGHT:
				var nav_path = _compute_path(active_char.position, pos)
				var sliced_path = _filter_by_optimized(nav_path)
				# todo: turn action logic
				active_char.action = CharacterCombatMovement.new(sliced_path)
				_project_path_to_terrain(nav_path)
		elif event is InputEventMouseMotion:
			var path = _compute_path(active_char.position, pos)
			_project_path_to_terrain(path)

# Display given path (discarding y component though) on the _terrain as a dashed
# line
func _project_path_to_terrain(path: PackedVector3Array) -> void:
	if path.size() > 1:
		var line_path = _make_omptimized_path2d(path)
		_terrain.set_next_pass_shader_parameter("line_vertices", line_path)
	else:
		var empty_path = PackedVector2Array()
		empty_path.resize(MAX_PATH_POINTS)
		empty_path.fill(Vector2(-1, -1))
		_terrain.set_next_pass_shader_parameter("line_vertices", empty_path)

# Compute 3D path from one global position to another. Assumes single
# navigation map is used, which will probably be always true in our context.
func _compute_path(from_pos: Vector3, to_pos: Vector3) -> PackedVector3Array:
	var params = NavigationPathQueryParameters3D.new()
	params.map = get_world_3d().get_navigation_map()
	params.start_position = from_pos
	params.target_position = to_pos
	var result = NavigationPathQueryResult3D.new()
	NavigationServer3D.query_path(params, result)
	return result.path

func _filter_by_optimized(path3d: PackedVector3Array) -> PackedVector3Array:
	var last_optimized_point = _make_omptimized_path2d(path3d)[-1];
	for i in range(0, path3d.size()):
		var vec = path3d[i]
		if last_optimized_point.x == vec.x and last_optimized_point.y == vec.z:
			return path3d.slice(0, i + 1)
	assert(false, "Panic: _filter_by_optimized didn't find the last point in original array")
	return PackedVector3Array() # just to make compiler happy

# Convert 3D path to 2D discaring the y coordinate and dropping less
# significant steps (steps where the angle changes just by few degrees or very
# short steps). Such path should only be used for visualization.
func _make_omptimized_path2d(path3d: PackedVector3Array) -> PackedVector2Array:
	# Min angle between two path segment to actually include the segment in
	# returned path
	const MIN_ANGLE = 0.04 * PI
	# Min length of the path segment to be included in the retruned path [m]
	const MIN_SEGMENT_LENGTH = 0.1

	var last_point_2d = Math.vec3_xz(path3d[-1])
	var path2d = PackedVector2Array()
	path2d.resize(MAX_PATH_POINTS)
	path2d.fill(last_point_2d)
	path2d[0] = Math.vec3_xz(path3d[0])
	path2d[1] = Math.vec3_xz(path3d[1])

	var path2d_i = 2
	var last_angle: float = -30

	for i in range(2, path3d.size()):
		var new_point = Vector2(path3d[i].x, path3d[i].z)
		var prev_point = path2d[path2d_i - 1]
		var current_angle = (new_point - prev_point).angle_to(Vector2.RIGHT)
		var very_short = new_point.distance_to(prev_point) < MIN_SEGMENT_LENGTH
		var same_direction = abs(last_angle - current_angle) < MIN_ANGLE
		last_angle = current_angle

		if same_direction or very_short:
			path2d[path2d_i - 1] = new_point
		else:
			path2d[path2d_i] = new_point
			path2d_i += 1
			if path2d_i == path2d.size():
				break

	return path2d

# Testing key handler to end any turn
func _unhandled_key_input(event: InputEvent) -> void:
	var end_turn = event.is_action_pressed("end_turn") and not event.is_echo()
	if end_turn:
		_combat.end_turn()
