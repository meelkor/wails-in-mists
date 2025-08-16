## Controls used in combat when it's player's turn and user is free to take an
## action
class_name CombatFreeControls
extends Node3D

## Number of path vertices supported by the terrain_project_pass shader. Needs
## to match the const defined there as well.
const MAX_PATH_POINTS = 6

var di := DI.new(self)

@onready var _combat := di.inject(Combat) as Combat
@onready var _terrain := di.inject(Terrain) as Terrain
@onready var _navigation := di.inject(Navigation) as Navigation
@onready var _spawned_npcs := di.inject(SpawnedNpcs) as SpawnedNpcs

@onready var _aoo_circle := $TerrainCircle as TerrainCircle


func _ready() -> void:
	_terrain.input_event.connect(_on_terrain_input_event)


func _exit_tree() -> void:
	TerrainLines.project_path(PackedVector3Array())
	_terrain.input_event.disconnect(_on_terrain_input_event)


func _on_terrain_input_event(event: InputEvent, pos: Vector3) -> void:
	var aoo_circle: TerrainCircle = $TerrainCircle

	if not _combat.is_free():
		aoo_circle.visible = false
		return

	var active_char := _combat.get_active_character()
	var available_steps := _combat.get_available_steps()
	var btn_event := event as InputEventMouseButton
	var motion_event := event as InputEventMouseMotion
	var navigable := _navigation.is_navigable(pos)
	if btn_event and navigable:
		if btn_event.is_released() and btn_event.button_index == MOUSE_BUTTON_LEFT and available_steps > 0:
			var nav_path := _compute_path(active_char.position, pos)
			var aoo := _find_aoo_on_path(nav_path)
			var movement := CharacterCombatMovement.new(nav_path)
			movement.max_length = available_steps
			if aoo:
				movement.red_highlight = aoo.segment
			active_char.action = movement
	elif motion_event and active_char.is_free():
		if navigable:
			var path := _compute_path(active_char.position, pos)
			var aoo := _find_aoo_on_path(path)
			if aoo:
				var chara_radius := (active_char.get_controller().character_scene.collision_shape.shape as CapsuleShape3D).radius
				_aoo_circle.visible = true
				_aoo_circle.position = aoo.character.position
				_aoo_circle.radius = aoo.character.get_aoo_reach() + chara_radius
				_aoo_circle.color = Color(Config.Palette.WARNING, 0.1)
				TerrainLines.project_path(path, available_steps, 0, aoo.segment)
			else:
				_aoo_circle.visible = false
				TerrainLines.project_path(path, available_steps, 0, Vector2.ZERO)

			GameCursor.use_default()
		else:
			TerrainLines.project_path([])
			GameCursor.use_ng()
			_aoo_circle.visible = false


func _find_aoo_on_path(path: PackedVector3Array) -> AooResult:
	_update_valid_reach_colliders()
	var start := _trace_cast_motion_reach(path, false)
	var end := _trace_cast_motion_reach(path, true)
	var red_hl := Vector2(0, 0)
	if not start.is_empty():
		red_hl.x = start["distance"]
	if not end.is_empty():
		red_hl.y = end["distance"]

	if red_hl.y == 0.:
		# show nothing if doesn't leave reach
		red_hl = Vector2(0, 0)
	elif red_hl.y > 0. and (red_hl.x == 0 or red_hl.x > red_hl.y):
		# If character only exits the danger zone
		red_hl.x = 0


	if red_hl.y > 0:
		var closest: GameCharacter = null
		var closest_dist: float = INF
		for part in _combat.get_participants():
			var distance_to_collision := part.position.distance_to(end["position"] as Vector3) - part.get_aoo_reach()
			if part.enemy and (not closest or distance_to_collision < closest_dist):
				closest = part
				closest_dist = distance_to_collision
		if closest:
			var out := AooResult.new()
			out.character = closest
			out.segment = red_hl
			return out
	return null


func _update_valid_reach_colliders() -> void:
	var valid_mask := Utils.get_collision_layer("character_reach_valid")
	for npc in _spawned_npcs.get_characters():
		var out_mask: int = int(_combat.has_npc(npc) and npc.enemy and npc.has_modifier_flag(&"aoo")) * valid_mask
		var area := npc.get_controller().reach_area
		area.collision_layer = (area.collision_layer & (~0 ^ valid_mask)) | out_mask



## Get actual mesh position under each point in provided path, since currently
## pathfinding find positions few cm above the actual ground mesh/collider, but
## for AoO simulation we need exact positions
func _snap_path_to_terrain(path: PackedVector3Array) -> PackedVector3Array:
	var out := path.duplicate()
	for i in range(path.size()):
		out[i] = _terrain.snap_down(path[i])
	return out


## Cast currently active character's collision shape along given path and find
## first (or last if from_end) reach area collision and return details about
## it. If no collision found, return empty dict.
func _trace_cast_motion_reach(path: PackedVector3Array, from_end: bool = false) -> Dictionary:
	path = _snap_path_to_terrain(path)
	var active_char := _combat.get_active_character()
	var active_ctrl := active_char.get_controller()
	var shape_query := PhysicsShapeQueryParameters3D.new()
	var ratio: float = -1
	var base := -1 if from_end else 0
	var direction := -1 if from_end else 1
	var pos := Vector3.INF
	var distance: float = 0
	var total_len: float = 0
	for segment_i in range(path.size() - 1):
		var current := path[base + segment_i * direction] + active_ctrl.character_scene.collision_shape.position
		var next := path[base + (segment_i + 1) * direction] + active_ctrl.character_scene.collision_shape.position
		shape_query.collide_with_areas = true
		shape_query.collide_with_bodies = false
		shape_query.collision_mask = Utils.get_collision_layer("character_reach_valid")
		shape_query.shape = active_ctrl.character_scene.collision_shape.shape
		shape_query.transform = Transform3D().translated(current)
		shape_query.motion = next - current
		shape_query.exclude = [active_ctrl.reach_area.get_rid()]
		var result := get_world_3d().direct_space_state.cast_motion(shape_query)
		if result[0] < 1.:
			ratio = result[0]
			pos = shape_query.transform.origin.lerp(shape_query.transform.origin + shape_query.motion, result[0])
			distance = total_len + current.distance_to(pos)
			if direction == 1:
				break
		total_len += current.distance_to(next)
	if pos != Vector3.INF:
		return {
			"ratio": ratio,
			"distance": total_len - distance if from_end else distance,
			"position": pos,
		}
	else:
		return {}


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


class AooResult:

	var character: GameCharacter

	var segment: Vector2
