class_name CharacterIdle
extends CharacterAction

func _init() -> void:
	avoidance_enabled = false
	static_obstacle = true

func start(ctrl: CharacterController) -> void:
	super.start(ctrl)
	ctrl.sheath_weapon()
	ctrl.update_animation(CharacterController.AnimationState.IDLE)
	ctrl.navigation_agent.avoidance_enabled = false
