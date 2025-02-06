## Movement action used by PlayableCharacters when the player is exploring
## freely. Uses the navigation agent with avoidance enabled.
class_name CharacterExplorationMovement
extends CharacterMovement


## Create CharacterExplorationMovement instance which moves towards given
## node's interaction collider until the moving character's interaction area
## collides
##
## todo: I hate this hate this hate this, but I hate everything around may
## implementation of movement so that's becoming a norm.
static func follow_node(node: Node3D) -> CharacterExplorationMovement:
	var movement := CharacterExplorationMovement.new(node.global_position)
	var collider: PhysicsBody3D
	if node is PhysicsBody3D:
		collider = node
	else:
		for obj: PhysicsBody3D in node.find_children("", "PhysicsBody3D"):
			if obj.collision_layer & Utils.get_collision_layer("interactable"):
				collider = obj
				break
	if collider:
		movement.followed_body = collider
	else:
		push_warning("Tried to follow node '%s' without collider" % node.name)
	return movement


## Body the character is trying to interact with. Finishes movement once the
## interaction area intersects this body.
##
## todo: half-assed solution for nicer "move to character", movement needs
## complete rework
var followed_body: PhysicsBody3D

## Location the character should be walking toward. May be inaccessible
@export var desired_goal: Vector3

## The actual found accessible point. Set when action starts.
@export var goal: Vector3

signal goal_computed(real_goal: Vector3)


func _init(new_goal: Vector3) -> void:
	avoidance_enabled = true
	static_obstacle = false
	desired_goal = new_goal


func start(ctrl: CharacterController) -> void:
	super.start(ctrl)

	ctrl.sheath_weapon()

	# navigation mesh rebaking apparently takes one frame, since setting
	# the target_position defereed after requesting the rebaking still results
	# in the agent using the old navigation mesh, in which the agent might have
	# been blocking the way to the desired goal.
	#
	# todo: try to find better solution. Maybe there is some
	# notification/signal when baking finishes??
	await ctrl.get_tree().process_frame

	if followed_body:
		# todo: somehow find the closest intersection between interaction area
		# and followed_body and set goal there?
		desired_goal = desired_goal.move_toward(ctrl.global_position, 0.8)

	ctrl.update_animation(CharacterController.AnimationState.IDLE)
	ctrl.navigation_agent.avoidance_enabled = true
	ctrl.navigation_agent.max_speed = ctrl.character.free_movement_speed
	ctrl.navigation_agent.target_position = desired_goal
	goal = ctrl.navigation_agent.get_final_position()
	goal_computed.emit(goal)


## Basically copies NavigationAgent's behaviour with little extra logic
func is_navigation_finished(ctrl: CharacterController) -> bool:
	if followed_body and ctrl.interaction_area.overlaps_body(followed_body):
		return true
	else:
		return ctrl.navigation_agent.is_navigation_finished() and _is_close_to(ctrl, goal)


## Basically copies NavigationAgent's behaviour with little extra logic
func get_velocity(ctrl: CharacterController) -> Vector3:
	var next_pos := ctrl.navigation_agent.get_next_path_position()
	var vec := (next_pos - ctrl.global_position).normalized()
	return vec


func get_next_action(_ctrl: CharacterController) -> CharacterAction:
	return CharacterIdle.new()
