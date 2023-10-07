class_name CharacterWalking
extends "res://logic/character_actions/action.gd"

var goal: Vector3

func _init(new_goal: Vector3):
	goal = new_goal
