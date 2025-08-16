extends Node3D

@onready var _player := $AnimationPlayer as AnimationPlayer

func _ready() -> void:
	_player.advance(Time.get_ticks_msec() / 1000.)
