class_name RoundGui
extends Control

var combat: Combat

# Dict of GameCharacter => PortraitScene
var portraits: Dictionary

### Lifecycle ###

func _ready() -> void:
	assert(combat, "Round GUI was created without setting combat reference")
	for character in combat.participant_order:
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
