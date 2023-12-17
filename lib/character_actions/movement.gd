# Abstract class that all actions that require CharacterController's movement
# should extend and properly implement its methods.
class_name CharacterMovement
extends CharacterAction

var movement_speed = 1.0

# Called every frame to check whether movement should end. Needs to be
# implemented in all movement actions!
func is_navigation_finished(_ctrl: CharacterController) -> bool:
	return true

# Called every frame during movement. The CharacterController tries to move in
# direction given by the returned normalized vector. The method used to
# actually move the controller depends on the avoidance configuration.
func get_velocity(_ctrl: CharacterController) -> Vector3:
	return Vector3.ZERO

# Since Movement actions "end by themselves", they need to be aware which
# action should be set afterwards.
func get_next_action(_ctrl: CharacterController) -> CharacterAction:
	return CharacterAction.new()

# Check whether the character is at given position with buffer suitable used
# for navigation purposes. Provided in this class so the logic is shared across
# all movement types.
func _is_close_to(ctrl: CharacterController, goal: Vector3) -> bool:
	var y_close = abs(goal.y - ctrl.global_position.y) < 1.0
	var diff = abs(goal - ctrl.global_position)
	var xz_close = diff.x < 0.07 and diff.z < 0.07
	return y_close and xz_close

