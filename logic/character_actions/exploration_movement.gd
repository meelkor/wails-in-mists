# Movement action used by PlayableCharacters when the player is exploring
# freely. Uses the navigation agent with avoidance enabled.
class_name CharacterExplorationMovement
extends CharacterMovement

# Location the character should be walking toward. May be inaccessible
var desired_goal: Vector3

# The actual found accessible point. Set when action starts.
var goal: Vector3

# Indicates that something fucky is going on with the path and we may want to
# recompute the path, since e.g. after evasion different path may be better
var _recompute_path = false

# Time since the last recomputation, so we don't recompute to often
var _recompute_timeout = 0

signal goal_computed(real_goal: Vector3)

### Public ###

func _init(new_goal: Vector3):
	movement_speed = 2.8
	avoidance_enabled = true
	static_obstacle = false
	desired_goal = new_goal

func start(ctrl: CharacterController):
	super.start(ctrl)

	if not ctrl.character.action is CharacterExplorationMovement:
		ctrl.current_speed = 0

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
	ctrl.navigation_agent.target_position = desired_goal
	goal = ctrl.navigation_agent.get_final_position()
	goal_computed.emit(goal)

func process(ctrl: CharacterController, delta: float):
	super.process(ctrl, delta)
	_recompute_timeout += delta

# Basically copies NavigationAgent's behaviour with little extra logic
func is_navigation_finished(ctrl: CharacterController) -> bool:
	if _recompute_path && _recompute_timeout > 0.5:
		ctrl.navigation_agent.target_position = goal
		_recompute_path = false
		_recompute_timeout = 0

	return ctrl.navigation_agent.is_navigation_finished() and _is_close_to(ctrl, goal)

# Basically copies NavigationAgent's behaviour with little extra logic
func get_velocity(ctrl: CharacterController) -> Vector3:
	var next_pos = ctrl.navigation_agent.get_next_path_position()
	var vec = (next_pos - ctrl.global_position).normalized()
	_check_next_position(ctrl, vec)
	return vec

func get_next_action(_ctrl) -> CharacterAction:
	return CharacterIdle.new()

### Private ###

# Compare the direction of the original vector and one computed by the
# navigation_agent and mark the path for recomputation if we are getting
# further from the original path.
func _check_next_position(ctrl: CharacterController, original_velocity: Vector3) -> void:
	var real_velocity = await ctrl.navigation_agent.velocity_computed
	if (original_velocity.normalized() - real_velocity.normalized()).length() > 0.1:
		_recompute_path = true

