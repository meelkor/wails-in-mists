## Helper which connects to one or more Colliders' events and observes for
## proper-clicks (= cursor started and ended the click on the collider and
## didn't move too much inbetween)
class_name ClickObserver
extends RefCounted

signal clicked()

var _last_pressed: InputEventMouseButton


func add(collider: CollisionObject3D) -> void:
	collider.input_event.connect(_on_collider_input)
	collider.mouse_exited.connect(func () -> void: _last_pressed = null)


func _on_collider_input(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	var btn := event as InputEventMouseButton
	if btn:
		if not btn.pressed:
			if _last_pressed:
				var mouse_travel_dist := _last_pressed.global_position.distance_to(btn.global_position)
				if mouse_travel_dist < 8:
					clicked.emit()
		else:
			_last_pressed = event
