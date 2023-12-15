class_name CharacterWalking
extends CharacterAction

# Location the character should be walking toward. May be inaccessible
var desired_goal: Vector3
# The actual found accessible point. Set when action starts.
var goal: Vector3

var movement_speed = 2.8

var t_since_start = 0
var waiting_for_rebake = false

func _init(new_goal: Vector3):
	desired_goal = new_goal

func start(ctrl: CharacterController):
	if not ctrl.action is CharacterWalking:
		ctrl.current_speed = 0

	if ctrl.is_in_group(KnownGroups.NAVIGATION_MESH_SOURCE):
		ctrl.remove_from_group(KnownGroups.NAVIGATION_MESH_SOURCE)
		global.rebake_navigation_mesh()

	t_since_start = 0
	waiting_for_rebake = true

func process(ctrl: CharacterController, delta: float):
	t_since_start += delta
	# navigation mesh rebaking apparently takes multiple frames, since setting
	# the target_position defereed after requesting the rebaking still results
	# in the agent using the old navigation mesh, in which the agent might have
	# been blocking the way to the desired goal.
	#
	# todo: try to find better solution. Maybe there is some
	# notification/signal when baking finishes??
	if waiting_for_rebake and t_since_start > 0.04:
		waiting_for_rebake = false
		ctrl.animation_player.play.call_deferred("run", -1, 0.90)
		ctrl.navigation_agent.avoidance_enabled = true
		ctrl.navigation_agent.target_position = desired_goal
		goal = ctrl.navigation_agent.get_final_position()
