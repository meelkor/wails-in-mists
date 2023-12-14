class_name CharacterWalking
extends CharacterAction

# Location the character should be walking toward. May be inaccessible
var desired_goal: Vector3
# The actual found accessible point. Set when action starts.
var goal: Vector3

var movement_speed = 2.8

func _init(new_goal: Vector3):
	desired_goal = new_goal

func start(ctrl: CharacterController):
	ctrl.navigation_agent.target_position = desired_goal
	goal = ctrl.navigation_agent.get_final_position()

	if not ctrl.action is CharacterWalking:
		ctrl.current_speed = 0

	ctrl._animation_player.play.call_deferred("run", -1, 0.90)

	if ctrl.is_in_group(KnownGroups.NAVIGATION_MESH_SOURCE):
		ctrl.remove_from_group(KnownGroups.NAVIGATION_MESH_SOURCE)
		global.rebake_navigation_mesh.call_deferred()
