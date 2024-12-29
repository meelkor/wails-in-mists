class_name LevelTester
extends Node

@export var disable_fow: bool = false

## Player state that is injected into the refrerenced level even though there's
## not GameInstance root node which would normally provide the state when
## running the game rather than single level scene.
@export var state: PlayerState

## Level we are testing. Usually this node's parent node.
@export var level: BaseLevel

@onready var _fps_label := $Fps as Label


func _enter_tree() -> void:
	# Create GameInstance which hold test player state
	var game := GameInstance.new()
	game.name = "GameInstance"
	add_child(game)
	game.state = state
	level.di.register(GameInstance, level.get_path_to(game))


func _ready() -> void:
	for chara in (level.di.inject(ControlledCharacters) as ControlledCharacters).get_characters():
		chara.fill_ability_bar()

	if disable_fow:
		var fow := get_parent().find_child("RustyFow") as RustyFow
		assert(fow)
		fow.visible = false


func _process(_delta: float) -> void:
	_fps_label.text = "%s" % Engine.get_frames_per_second()
