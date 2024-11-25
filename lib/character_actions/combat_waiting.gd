# Action set during combat to all idle not-controlled participants. When it's
# character's turn and it's waiting for player command, CharacterCombatReady is
# used instead.
class_name CharacterCombatWaiting
extends CharacterAction

func _init() -> void:
	avoidance_enabled = false
	static_obstacle = true


func start(ctrl: CharacterController) -> void:
	super.start(ctrl)
	await ctrl.draw_weapon()
	ctrl.update_animation(CharacterController.AnimationState.COMBAT)
