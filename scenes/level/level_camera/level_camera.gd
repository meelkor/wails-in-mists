class_name LevelCamera
extends Camera3D

signal rect_selected(rect: Rect2)

var last_pos: Vector2 = Vector2.ZERO
var panning: bool = false

var default_y = 16
# TODO: Actually calculate form the height and fov. Somehow.
var direct_offset = Vector3(0, 0, 8)
var desired_y = default_y
var y_move_speed = 0.25 # /s
var y_move_multiplier = 0.1

var selecting_from: Vector2 = Vector2.ZERO

func _process(_delta):
	$RayCast3D.target_position = position - direct_offset
	$RayCast3D.target_position.y = -1000

func _physics_process(delta):
	var y_to_travel = desired_y - position.y
	var y_to_travel_abs = abs(y_to_travel)
	if y_to_travel_abs > 0.01:
		var jump = sign(y_to_travel) * min(y_to_travel_abs, delta * y_move_speed * y_move_multiplier * y_to_travel_abs)
		position.y += jump
		y_move_multiplier *= 1 + (1.8 * delta)
	else:
		y_move_multiplier = 1

func _unhandled_input(e):
	if e is InputEventMouseMotion:
		if panning:
			var diff = last_pos - e.position
			last_pos = e.position
			position += Vector3(diff.x * 0.014, 0.0, diff.y * 0.014)
			var new_y = default_y + $RayCast3D.get_collision_point().y
			if abs(new_y - desired_y) > 2.0:
				desired_y = new_y
	elif e is InputEventMouseButton:
		# TODO: hacky solution of zooming just for testing purposes
		if e.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
			default_y += 1
			desired_y += 1
			position.y += 1
			position.z += 0.55
		elif e.button_index == MouseButton.MOUSE_BUTTON_WHEEL_UP:
			default_y -= 1
			desired_y -= 1
			position.y -= 1
			position.z -= 0.55
		if e.is_pressed() && e.button_index == MouseButton.MOUSE_BUTTON_MIDDLE:
			panning = true
			last_pos = e.position
		elif e.is_released():
			panning = false

	if e is InputEventMouseButton:
		if e.is_pressed() && e.button_index == MOUSE_BUTTON_LEFT:
			selecting_from = e.position
		if e.is_released():
			if e.button_index == MOUSE_BUTTON_LEFT && is_rect_selecting():
				rect_selected.emit(get_selection_rect(e.position))
				$Line2D.clear_points()
				selecting_from = Vector2.ZERO
	elif e is InputEventMouseMotion:
		if e.button_mask == MOUSE_BUTTON_MASK_LEFT && is_rect_selecting():
			var rect = get_selection_rect(e.position)
			draw_rect2_as_line($Line2D, rect)

# Move camera to look at the given coordinate in the game world, correctly
# setting its position, without modifying its rotation
func move_to(pos: Vector3):
	position = Vector3(pos.x, default_y + $RayCast3D.get_collision_point().y, pos.z) + direct_offset

func get_selection_rect(current_pos: Vector2) -> Rect2:
	var dims = selecting_from - current_pos
	return Rect2(
		Vector2(
			min(current_pos.x, selecting_from.x),
			min(current_pos.y, selecting_from.y),
		),
		dims.abs(),
	)

func is_rect_selecting() -> bool:
	return selecting_from != Vector2.ZERO

func draw_rect2_as_line(line2d: Line2D, rect: Rect2) -> void:
	var bottom_right = rect.position + rect.size
	var top_left = rect.position
	line2d.clear_points()
	line2d.add_point(top_left)
	line2d.add_point(Vector2(bottom_right.x, top_left.y))
	line2d.add_point(bottom_right)
	line2d.add_point(Vector2(top_left.x, bottom_right.y))
	line2d.add_point(top_left)
