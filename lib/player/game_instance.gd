## Root node which contains player's "global" (=not level specific) state and
## takes care of switching levels when requested.
class_name GameInstance
extends Node

@export var state: PlayerState


func _ready() -> void:
	# todo: I hate that the Character class can't take care of this itself but
	# at the same time I understand that Resources shouldn't be "active" :((
	# Related: https://github.com/godotengine/godot/issues/68427
	for chara in state.characters:
		chara.available_talents.connect_active_talents(chara.talents)
