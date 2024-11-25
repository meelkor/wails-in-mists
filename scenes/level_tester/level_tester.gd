class_name LevelTester
extends Node

@export var disable_fow: bool = false

@export var level: BaseLevel

@onready var _fps_label := $Fps as Label


func mk_chr() -> GameCharacter:
	var test_char2 := PlayableCharacter.new()
	test_char2.name = "Test Character 2"
	test_char2.portrait = "res://resources/portraits/placeholder_2.png"
	test_char2.hair = preload("res://models/hair0v2.glb")
	test_char2.hair_color = Color.DARK_GOLDENROD
	test_char2.equipment.add_entity(WeaponRef.new(preload("res://game_resources/playground/short_sword.tres")), ItemEquipment.Slot.MAIN)
	var prof := TalentProficiency.new()
	prof.l1_types.append(WeaponMeta.TypeL1Id.MELEE)
	test_char2.available_talents.add_entity(TalentPack.new([prof]))
	return test_char2


func _ready() -> void:
	global.PLAYER_STATE_PATH = $PlayerState.get_path()
	global.CONTROLLED_CHARACTERS_PATH = level.get_node("ControlledCharacters").get_path()
	var test_char := PlayableCharacter.new()
	test_char.name = "Test Character"
	test_char.hair = preload("res://models/hair0v2.glb")
	test_char.hair_color = Color.FOREST_GREEN
	var initiative_bonus := TalentSkillBonus.new()
	initiative_bonus.skill = Skills.INITIATIVE
	initiative_bonus.amount = 20
	var in_bonus_pack := TalentPack.new([initiative_bonus])
	test_char.talents.add_entity(in_bonus_pack)
	test_char.available_talents.add_entity(in_bonus_pack)
	test_char.equipment.add_entity(WeaponRef.new(preload("res://game_resources/playground/sparky_sword.tres")), ItemEquipment.Slot.MAIN)
	test_char.set_attribute(CharacterAttributes.WILL, 2)

	level.spawn_playable_characters([test_char, mk_chr(), mk_chr(), mk_chr()])

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

	for chara in (level.get_node("ControlledCharacters") as ControlledCharacters).get_characters():
		chara.fill_ability_bar()

	if disable_fow:
		var fow := get_parent().find_child("RustyFow") as RustyFow
		assert(fow)
		fow.visible = false


func _process(_delta: float) -> void:
	_fps_label.text = "%s" % Engine.get_frames_per_second()
