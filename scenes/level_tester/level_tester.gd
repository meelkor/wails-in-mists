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

var _game_instance: GameInstance


func _enter_tree() -> void:
	# Create GameInstance which hold test player state
	_game_instance = GameInstance.new()
	_game_instance.name = "GameInstance"
	_game_instance.state = state
	add_child(_game_instance)
	level.di.register(GameInstance, level.get_path_to(_game_instance))


func _ready() -> void:

	for chara in _game_instance.state.characters:
		for pack in chara.available_talents.get_all():
			if chara.talents.size() < chara.get_talent_slot_count():
				chara.talents.add_entity(pack)
		chara.fill_ability_bar()

	if disable_fow:
		var fow := get_parent().find_child("RustyFow") as RustyFow
		assert(fow)
		fow.visible = false


func _process(_delta: float) -> void:
	_fps_label.text = "%s" % Engine.get_frames_per_second()
