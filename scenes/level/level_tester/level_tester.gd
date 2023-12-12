class_name LevelTester
extends Node

@export var disable_fow: bool = false

func _ready() -> void:
	global.MESSAGE_LOG_PATH = $MessageLog.get_path()
	var level_scn = get_parent().find_children("", "BaseLevel")[0] as BaseLevel
	var test_char = PlayableCharacter.new("Test Character")
	level_scn.spawn_playable_characters([test_char])

	if disable_fow:
		var fow = get_parent().find_child("RustyFow") as RustyFow
		assert(fow)
		fow.visible = false
