class_name CharacterIdle
extends "res://logic/character_actions/action.gd"

func _init():
	pass

func start(ctrl: CharacterController) -> void:
	ctrl._animation_player.play.call_deferred("idle")

	if not ctrl.is_in_group(KnownGroups.NAVIGATION_MESH_SOURCE):
		ctrl.add_to_group(KnownGroups.NAVIGATION_MESH_SOURCE)
		global.rebake_navigation_mesh()
