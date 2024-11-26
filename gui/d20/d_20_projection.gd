@tool
extends Node

var roll_result: Dice.Result

@export var success: bool

@onready var _player := $AnimationPlayer as AnimationPlayer
@onready var _label := $NumberLabel as Label


func _ready() -> void:
	_label.text = str(roll_result.roll)
	_player.get_animation("roll").track_set_key_value(4, 2, Color("#009de3") if roll_result.success else Color("#ff4800"))
	_player.play("roll")
