# Movement action that should be used during combat. Compared to movement
# during exploration this action doesn't use the navigation agent or avoidance
# and strictly follows the provided pre-calculated path.
class_name CharacterCombatMovement
extends CharacterMovement

# Exact path the character should follow
var path: PackedVector3Array

func _init(exact_path: PackedVector3Array):
	avoidance_enabled = false
	static_obstacle = false
	movement_speed = 1.8
	path = exact_path

func start(ctrl: CharacterController):
	super.start(ctrl)
	# todo: use the not yet existing combat_movement animation
	ctrl.animation_player.play("run", -1, 0.90)

func is_navigation_finished(ctrl: CharacterController):
	return _is_close_to(ctrl, path[-1])

func get_velocity(ctrl: CharacterController):
	while true:
		if path.size() == 0:
			return Vector3.ZERO
		else:
			var next = path[0]
			var close_to_next = _is_close_to(ctrl, next)
			if close_to_next:
				path.remove_at(0)
			else:
				var velocity = (next - ctrl.global_position)
				var orig_y = velocity.y
				velocity.y = 0
				velocity = velocity.normalized()
				velocity.y = orig_y
				return velocity

func get_next_action(_ctrl):
	return CharacterCombatReady.new(false)
