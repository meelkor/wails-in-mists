## Abstract class all character actions should extend. Character action dictates
## most of the behaviour of the character controller in current gameplay
## session. The actions are not stored. To make the configuration options such
## as static_obstacle and avoidance_enabled work, don't forget to call
## super.(start|process|end) in action's overrides.
extends RefCounted
class_name CharacterAction

## Usually we want the avoidance to be enabled only when the character is
## moving.
var avoidance_enabled = false

## Static obstacle should be true if we want the navigation mesh to have "hole"
## around the player. Useful for idle characters for which we want to navigate
## around.
var static_obstacle = false


func start(ctrl: CharacterController):
	ctrl.navigation_agent.avoidance_enabled = avoidance_enabled
	if static_obstacle:
		if not ctrl.is_in_group(KnownGroups.NAVIGATION_MESH_SOURCE):
			ctrl.add_to_group(KnownGroups.NAVIGATION_MESH_SOURCE)
			global.rebake_navigation_mesh()
	else:
		if ctrl.is_in_group(KnownGroups.NAVIGATION_MESH_SOURCE):
			ctrl.remove_from_group(KnownGroups.NAVIGATION_MESH_SOURCE)
			global.rebake_navigation_mesh()

func process(_v: CharacterController, _delta: float):
	pass

func end(_v: CharacterController):
	pass
