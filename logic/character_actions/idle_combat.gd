class_name CharacterIdleCombat
extends CharacterIdle

func start(ctrl: CharacterController) -> void:
	ctrl.animation_player.play("ready_weapon")
