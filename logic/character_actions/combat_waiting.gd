# Action set during combat to all idle not-controlled participants. When it's
# character's turn and it's waiting for player command, CharacterCombatReady is
# used instead.
class_name CharacterCombatWaiting
extends CharacterAction

func _init():
	avoidance_enabled = false
	static_obstacle = true

func start(ctrl: CharacterController) -> void:
	super.start(ctrl)
	# todo: do not play ready weapon when already on combat idle animation
	ctrl.animation_player.play("ready_weapon")
