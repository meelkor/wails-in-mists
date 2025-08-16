## Movement action that should be used during combat. Compared to movement
## during exploration this action doesn't use the navigation agent or avoidance
## and strictly follows the provided pre-calculated path.
class_name CharacterCombatMovement
extends CharacterMovement

## Exact path the character should follow
var path: PackedVector3Array

## Which part of the path should be highlighted red because of possible AoO
var red_highlight: Vector2 = Vector2.ZERO


func _init(exact_path: PackedVector3Array) -> void:
	avoidance_enabled = false
	static_obstacle = false
	path = exact_path


func is_navigation_finished(ctrl: CharacterController) -> bool:
	return _is_close_to(ctrl, path[-1])


## todo: still not sure how the whole "clicking while moving in combat" should
## work, so for now free is false
func is_free() -> bool:
	return false


func get_velocity(ctrl: CharacterController) -> Vector3:
	while true:
		if path.size() == 0:
			return Vector3.ZERO
		else:
			var next := path[0]
			var close_to_next := _is_close_to(ctrl, next)
			if close_to_next:
				path.remove_at(0)
			else:
				var velocity := (next - ctrl.global_position)
				var orig_y := velocity.y
				velocity.y = 0
				velocity = velocity.normalized()
				velocity.y = orig_y
				return velocity
	return Vector3.ZERO


## todo: should be prolly handled by explo/combat controller
func get_next_action(_ctrl: CharacterController) -> CharacterAction:
	return CharacterCombatReady.new()
