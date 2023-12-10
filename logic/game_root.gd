class_name GameRoot
extends Node

func _ready():
	var player_state = global.player_state()

	player_state.characters.append(PlayableCharacter.new("Rozemyne"))
	player_state.characters.append(PlayableCharacter.new("Charlotte"))
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
	wpn.slot.append(EquipmentSlot.MAIN)
	wpn.slot.append(EquipmentSlot.OFF)
	return wpn

func _make_test_armor(aname: String) -> EquipmentItem:
	var armor = EquipmentItem.new()
	armor.name = aname
	armor.slot.append(EquipmentSlot.ARMOR)
	return armor
