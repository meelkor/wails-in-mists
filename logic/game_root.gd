class_name GameRoot
extends Node

func _ready():
	var player_state = global.player_state()

	var rozemyne = PlayableCharacter.new("Rozemyne")
	rozemyne.hair = "res://models/hair0.glb"
	rozemyne.hair_color = Color.FOREST_GREEN
	rozemyne.set_equipment(Equipment.Slot.ARMOR, _make_test_armor("Epic", "res://textures/medium_armor_gray_character_tex.png"))
	player_state.characters.append(rozemyne)

	var charlotte = PlayableCharacter.new("Charlotte")
	charlotte.hair = "res://models/hair0.glb"
	charlotte.hair_color = Color.HOT_PINK
	charlotte.skin_color = Color.BISQUE
	charlotte.set_equipment(Equipment.Slot.ARMOR, _make_test_armor("Less Epic", "res://textures/medium_armor_character_tex.png"))
	player_state.characters.append(charlotte)

	player_state.characters.append(PlayableCharacter.new("Brunhilde"))

	player_state.inventory.items.append(_make_test_wpn("Short Sword 1"))
	player_state.inventory.items.append(_make_test_wpn("Short Sword 2"))
	player_state.inventory.items.append(_make_test_wpn("Short Sword 3"))
	player_state.inventory.items.append(_make_test_wpn("Scythe"))
	player_state.inventory.items.append(_make_test_wpn("Bow"))
	player_state.inventory.items.append(_make_test_wpn("Mace"))
	player_state.inventory.items.append(_make_test_wpn("Morning Star"))

	player_state.inventory.items.append(_make_test_armor("Leather Armor"))
	player_state.inventory.items.append(_make_test_armor("Black Leather Armor"))

	($Level as BaseLevel).spawn_playable_characters(player_state.characters)

func _make_test_wpn(wname: String) -> WeaponItem:
	var wpn = WeaponItem.new()
	wpn.name = wname
	wpn.attack = 7
	wpn.damage = 2
	wpn.slot.append(Equipment.Slot.MAIN)
	wpn.slot.append(Equipment.Slot.OFF)
	return wpn

func _make_test_armor(aname: String, texture: String = "") -> EquipmentItem:
	var armor = EquipmentItem.new()
	armor.name = aname
	if texture:
		armor.character_texture = texture
		armor.model = "res://models/medium_armor.glb"
	armor.slot.append(Equipment.Slot.ARMOR)
	return armor
