## Abstract class all character actions should extend. Character action dictates
## most of the behaviour of the character controller in current gameplay
## session. The actions are not stored. To make the configuration options such
## as static_obstacle and avoidance_enabled work, don't forget to call
## super.(start|process|end) in action's overrides.
extends RefCounted
class_name CharacterAction

## Usually we want the avoidance to be enabled only when the character is
## moving.
var avoidance_enabled := false

## Static obstacle should be true if we want the navigation mesh to have "hole"
## around the player. Useful for idle characters for which we want to navigate
## around.
var static_obstacle := false


## Can be implemented by subclass to make sure player cannot control the
## character while the action is active
func is_free() -> bool:
	return true


func start(ctrl: CharacterController) -> void:
	ctrl.navigation_agent.avoidance_enabled = avoidance_enabled


func process(_v: CharacterController, _delta: float) -> void:
	pass


func end(_v: CharacterController) -> void:
	pass
