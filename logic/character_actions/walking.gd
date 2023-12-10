class_name CharacterWalking
extends CharacterAction

var goal: Vector3

func _init(new_goal: Vector3):
	goal = new_goal

func start(ctrl: CharacterController):
	if ctrl.action != CharacterWalking:
		ctrl.current_speed = 0

	ctrl._animation_player.play.call_deferred("run", -1, 0.90)
