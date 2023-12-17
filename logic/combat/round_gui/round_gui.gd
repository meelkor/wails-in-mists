class_name RoundGui
extends Control

var _combat: Combat

# Dict of GameCharacter => PortraitScene
var _portraits: Dictionary

### Public ###

func set_combat(combat: Combat) -> void:
	_combat = combat

	for character in combat._participant_order:
		var FramedDialogScene = preload("res://scenes/ui/framed_dialog/framed_dialog.tscn") as PackedScene
		var framed_dialog = FramedDialogScene.instantiate()
		var charname_label = Label.new()
		charname_label.text = character.name
		var hp_label = Label.new()
		hp_label.text = "%s / %s" % [combat.get_hp(character), Ruleset.calculate_max_hp(character)]
		hp_label.position = Vector2(0, 30)
		if character is NpcCharacter:
			if character.is_enemy:
				framed_dialog.border_tint = Color.from_string("a63a7a64", Color.TRANSPARENT)
			else:
				framed_dialog.border_tint = Color.from_string("235900b7", Color.TRANSPARENT)
		else:
			framed_dialog.border_tint = Color.from_string("166a9ec9", Color.TRANSPARENT)
		framed_dialog.custom_minimum_size = Vector2(100, 130)

		framed_dialog.add_child(charname_label)
		framed_dialog.add_child(hp_label)
		$HBoxContainer.add_child(framed_dialog)
		_portraits[character] = framed_dialog
		# todo: create some CombatPortrait scene and use it instead of ^^^

	combat.progressed.connect(_update_active_character)
	await get_tree().process_frame
	_update_active_character()

func _update_active_character() -> void:
	for portrait in _portraits.values():
		portrait.scale = Vector2(0.4, 0.4)
	var character = _combat.get_active_character()
	_portraits[character].scale = Vector2.ONE
