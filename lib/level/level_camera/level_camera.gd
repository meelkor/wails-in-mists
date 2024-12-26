class_name LevelCamera
extends Camera3D

const INITIAL_DEFAULT_Y = 20.

var last_pos: Vector2 = Vector2.ZERO
var panning: bool = false

var default_y := INITIAL_DEFAULT_Y
# TODO: Actually calculate form the height and fov. Somehow.
var direct_offset := Vector3(0, 0, 9)
var desired_y := default_y
var y_move_speed := 0.25 # /s
var y_move_multiplier := 0.1
var moved: bool = false
var _mouse_in_window: bool = true

## Normalized vector camera should "edge scroll" to
var edging: Vector3 = Vector3.ZERO

var _last_camera_pos: Vector3

@onready var _raycast := $RayCast3D as RayCast3D
@onready var initial_x_rotation := rotation.x


## Move camera to look at the given coordinate in the game world, correctly
## setting its position, without modifying its rotation
func move_to(pos: Vector3) -> void:
	# fixme: the raycast uses current position, not the position it will have
	# after the move
	position = Vector3(pos.x, default_y + _raycast.get_collision_point().y, pos.z) + direct_offset


func _process(delta: float) -> void:
	moved = _last_camera_pos != global_position
	_last_camera_pos = global_position
	if _mouse_in_window:
		position += edging * delta * 10 # move 10m/s when edge scrolling
	rotation.x = initial_x_rotation * (default_y / INITIAL_DEFAULT_Y)
	_raycast.target_position = position - direct_offset
	_raycast.target_position.y = -1000


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_check_edge_scrolling_state()


func _physics_process(delta: float) -> void:
	var y_to_travel := desired_y - position.y
	var y_to_travel_abs := abs(y_to_travel) as float
	if y_to_travel_abs > 0.01:
		var jump := sign(y_to_travel) * min(y_to_travel_abs, delta * y_move_speed * y_move_multiplier * y_to_travel_abs) as float
		position.y += jump
		y_move_multiplier *= 1 + (1.8 * delta)
	else:
		y_move_multiplier = 1


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_ENTER:
		_mouse_in_window = true
	elif what == NOTIFICATION_WM_MOUSE_EXIT:
		_mouse_in_window = false


func _unhandled_input(e: InputEvent) -> void:
	var motion := e as InputEventMouseMotion
	var btn := e as InputEventMouseButton
	if motion and panning:
		var diff := last_pos - motion.position
		last_pos = motion.position
		position += Vector3(diff.x * 0.014, 0.0, diff.y * 0.014)
		var new_y := default_y + _raycast.get_collision_point().y
		if abs(new_y - desired_y) > 2.0:
			desired_y = new_y
	elif btn:
		# TODO: hacky solution of zooming just for testing purposes
		if btn.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
			default_y += 1
			desired_y += 1
			position.y += 1
			position.z += 0.55
			near = default_y * 0.4
		elif btn.button_index == MouseButton.MOUSE_BUTTON_WHEEL_UP:
			default_y -= 1
			desired_y -= 1
			position.y -= 1
			position.z -= 0.55
			near = default_y * 0.4
		if btn.is_pressed() && btn.button_index == MouseButton.MOUSE_BUTTON_MIDDLE:
			panning = true
			last_pos = btn.position
		elif e.is_released():
			panning = false


func _check_edge_scrolling_state() -> void:
	var real_position := _get_real_mouse_position()
	var win_size := get_window().size - Vector2i(1, 1)
	var scrolling_threshold := 2 * get_window().content_scale_factor;
	if not panning:
		if real_position.x <= scrolling_threshold:
			edging.x = -1
		elif real_position.x >= win_size.x - scrolling_threshold:
			edging.x = 1
		else:
			edging.x = 0
		if real_position.y <= scrolling_threshold:
			edging.z = -1
		elif real_position.y >= win_size.y - scrolling_threshold:
			edging.z = 1
		else:
			edging.z = 0


## Didn't find another reasonable way to get real mouse position factoring in
## the scaling, aspect ration, resolution etc.
func _get_real_mouse_position() -> Vector2i:
	var win := get_window()
	# In viewport units (0-1920, 0-1080)
	var viewport_pos := get_viewport().get_mouse_position()
	# Real window size
	var win_size := Vector2(win.size)
	# Constant size defined in setting (1920, 1080), stays the same even when
	# aspect ratio changes
	var scale_size := Vector2(win.content_scale_size)
	var aspect_scale := Vector2(1, scale_size.x / scale_size.y / (win_size.x / win_size.y))
	var real_position := viewport_pos * win.content_scale_factor / scale_size / aspect_scale * win_size
	return Vector2i(real_position)

