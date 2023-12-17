class_name CharacterIdle
extends CharacterAction

func _init():
	avoidance_enabled = false
	static_obstacle = true

func start(ctrl: CharacterController) -> void:
	super.start(ctrl)
	ctrl.animation_player.play.call_deferred("idle")
	ctrl.navigation_agent.avoidance_enabled = false
