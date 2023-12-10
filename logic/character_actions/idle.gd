class_name CharacterIdle
extends "res://logic/character_actions/action.gd"

func _init():
	pass

func start(ctrl: CharacterController) -> void:
	ctrl._animation_player.play.call_deferred("idle")
