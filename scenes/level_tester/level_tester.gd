class_name LevelTester
extends Node

@export var disable_fow: bool = false

@export var level: BaseLevel

func _ready() -> void:
	global.PLAYER_STATE_PATH = $PlayerState.get_path()
	global.CONTROLLED_CHARACTERS_PATH = level.get_node("ControlledCharacters").get_path()
	var test_char = PlayableCharacter.new()
	test_char.name = "Test Character"
	test_char.hair = preload("res://models/hair0.glb")
	test_char.hair_color = Color.FOREST_GREEN
	var test_char2 = PlayableCharacter.new()
	test_char2.name = "Test Character 2"
	test_char2.hair = preload("res://models/hair0.glb")
	test_char2.hair_color = Color.DARK_GOLDENROD
	level.spawn_playable_characters([test_char, test_char2])

	test_char.equipment.equip(ItemEquipment.Slot.MAIN, preload("res://game_resources/playground/sparky_sword.tres"))

	if disable_fow:
		var fow = get_parent().find_child("RustyFow") as RustyFow
		assert(fow)
		fow.visible = false
