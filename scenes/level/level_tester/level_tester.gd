class_name LevelTester
extends Node

@export var disable_fow: bool = false

@export var level: BaseLevel

func _ready() -> void:
	global.MESSAGE_LOG_PATH = $MessageLog.get_path()
	global.PLAYER_STATE_PATH = $PlayerState.get_path()
	global.CONTROLLED_CHARACTERS_PATH = level.get_node("ControlledCharacters").get_path()
	var test_char = PlayableCharacter.new("Test Character")
	test_char.hair = "res://models/hair0.glb"
	test_char.hair_color = Color.FOREST_GREEN
	level.spawn_playable_characters([test_char])

	var player_state = $PlayerState
	player_state.inventory.items.append(_make_test_wpn("Short Sword 1"))
	player_state.inventory.items.append(_make_test_armor("Leather Armor", "res://textures/medium_armor_gray_character_tex.png"))
	player_state.inventory.items.append(_make_test_armor("Black Leather Armor", "res://textures/medium_armor_character_tex.png"))

	if disable_fow:
		var fow = get_parent().find_child("RustyFow") as RustyFow
		assert(fow)
		fow.visible = false

func _make_test_wpn(wname: String) -> WeaponItem:
	var wpn = WeaponItem.new()
	wpn.name = wname
	wpn.attack = 7
	wpn.damage = 2
	wpn.slot.append(Equipment.Slot.MAIN)
	wpn.slot.append(Equipment.Slot.OFF)
	wpn.model_bone = AttachableBone.WEAPON_SMALL
	wpn.model = "models/short_sword.glb"
	return wpn

func _make_test_armor(aname: String, texture: String = "") -> EquipmentItem:
	var armor = EquipmentItem.new()
	armor.name = aname
	if texture:
		armor.character_texture = texture
		armor.model = "res://models/medium_armor.glb"
	armor.slot.append(Equipment.Slot.ARMOR)
	return armor
