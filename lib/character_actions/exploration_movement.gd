## Movement action used by PlayableCharacters when the player is exploring
## freely. Uses the navigation agent with avoidance enabled.
class_name CharacterExplorationMovement
extends CharacterMovement

## Location the character should be walking toward. May be inaccessible
var desired_goal: Vector3

## The actual found accessible point. Set when action starts.
var goal: Vector3

signal goal_computed(real_goal: Vector3)


func _init(new_goal: Vector3) -> void:
	movement_speed = 2.8
	avoidance_enabled = true
	static_obstacle = false
	desired_goal = new_goal


func start(ctrl: CharacterController) -> void:
	super.start(ctrl)

	# navigation mesh rebaking apparently takes one frame, since setting
	# the target_position defereed after requesting the rebaking still results
	# in the agent using the old navigation mesh, in which the agent might have
	# been blocking the way to the desired goal.
	#
	# todo: try to find better solution. Maybe there is some
	# notification/signal when baking finishes??
	await ctrl.get_tree().process_frame

	ctrl.animation_player.play.call_deferred("run", -1, 0.90)
	ctrl.navigation_agent.avoidance_enabled = true
	ctrl.navigation_agent.max_speed = movement_speed
	ctrl.navigation_agent.target_position = desired_goal
	goal = ctrl.navigation_agent.get_final_position()
	goal_computed.emit(goal)


## Basically copies NavigationAgent's behaviour with little extra logic
func is_navigation_finished(ctrl: CharacterController) -> bool:
	return ctrl.navigation_agent.is_navigation_finished() and _is_close_to(ctrl, goal)


## Basically copies NavigationAgent's behaviour with little extra logic
func get_velocity(ctrl: CharacterController) -> Vector3:
	var next_pos := ctrl.navigation_agent.get_next_path_position()
	var vec := (next_pos - ctrl.global_position).normalized()
	return vec


func get_next_action(_ctrl: CharacterController) -> CharacterAction:
	return CharacterIdle.new()
