class_name CharacterIdle
extends "res://logic/character_actions/action.gd"

func _init():
	pass

func start(ctrl: CharacterController) -> void:
	ctrl.animation_player.play.call_deferred("idle")
	ctrl.navigation_agent.avoidance_enabled = false

	if not ctrl.is_in_group(KnownGroups.NAVIGATION_MESH_SOURCE):
		ctrl.add_to_group(KnownGroups.NAVIGATION_MESH_SOURCE)
		global.rebake_navigation_mesh()
