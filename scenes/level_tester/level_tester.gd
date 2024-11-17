class_name LevelTester
extends Node

@export var disable_fow: bool = false

@export var level: BaseLevel

func _ready() -> void:
	global.PLAYER_STATE_PATH = $PlayerState.get_path()
	global.CONTROLLED_CHARACTERS_PATH = level.get_node("ControlledCharacters").get_path()
	var test_char := PlayableCharacter.new()
	test_char.name = "Test Character"
	test_char.hair = preload("res://models/hair0v2.glb")
	test_char.hair_color = Color.FOREST_GREEN
	var test_char2 := PlayableCharacter.new()
	test_char2.name = "Test Character 2"
	test_char2.hair = preload("res://models/hair0v2.glb")
	test_char2.hair_color = Color.DARK_GOLDENROD
	level.spawn_playable_characters([test_char, test_char2])

	test_char.equipment.add_entity(WeaponRef.new(preload("res://game_resources/playground/sparky_sword.tres")), ItemEquipment.Slot.MAIN)
	test_char.set_attribute(CharacterAttributes.WILL, 2)
	test_char2.equipment.add_entity(WeaponRef.new(preload("res://game_resources/playground/short_sword.tres")), ItemEquipment.Slot.MAIN)
	var prof := TalentProficiency.new()
	prof.l1_types.append(WeaponMeta.TypeL1Id.MELEE)
	test_char2.available_talents.add_entity(TalentPack.new([prof]))

	global.player_state().inventory.add_entity(WeaponRef.new(preload("res://game_resources/playground/sparky_sword.tres")))
	global.player_state().inventory.add_entity(StackRef.new(preload("res://game_resources/playground/mist_shard.tres")))
	global.player_state().inventory.add_entity(StackRef.new(preload("res://game_resources/playground/mist_shard.tres")))
	global.player_state().inventory.add_entity(StackRef.new(preload("res://game_resources/playground/mist_shard.tres")))
	global.player_state().inventory.add_entity(StackRef.new(preload("res://game_resources/playground/mist_shard.tres")))
	global.player_state().inventory.add_entity(StackRef.new(preload("res://game_resources/playground/mist_shard.tres")))
	global.player_state().inventory.add_entity(StackRef.new(preload("res://game_resources/playground/mist_shard.tres")))
	global.player_state().inventory.add_entity(StackRef.new(preload("res://game_resources/playground/mist_shard.tres")))
	global.player_state().inventory.add_entity(StackRef.new(preload("res://game_resources/playground/mist_shard.tres")))
	global.player_state().inventory.add_entity(StackRef.new(preload("res://game_resources/playground/mist_shard.tres")))
	global.player_state().inventory.add_entity(StackRef.new(preload("res://game_resources/playground/mist_shard.tres")))
	global.player_state().inventory.add_entity(StackRef.new(preload("res://game_resources/playground/mist_shard.tres")))
	global.player_state().inventory.add_entity(StackRef.new(preload("res://game_resources/playground/mist_shard.tres")))

	test_char.fill_ability_bar()
	test_char2.fill_ability_bar()

	if disable_fow:
		var fow := get_parent().find_child("RustyFow") as RustyFow
		assert(fow)
		fow.visible = false
