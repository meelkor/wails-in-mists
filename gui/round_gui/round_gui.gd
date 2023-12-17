class_name RoundGui
extends Control

var _combat: Combat

# Dict of GameCharacter => ParticipantPortrait
var _portraits: Dictionary

### Public ###

func set_combat(combat: Combat) -> void:
	_combat = combat

	for character in combat._participant_order:
		var ParticipantPortraitScene = preload("res://gui/participant_portrait/participant_portrait.tscn") as PackedScene
		var portrait = ParticipantPortraitScene.instantiate()
		$HBoxContainer.add_child(portrait)
		_portraits[character] = portrait
		# todo: create some CombatPortrait scene and use it instead of ^^^

	# combat.progressed.connect(_update_active_character)
	await get_tree().process_frame
	# _update_active_character()

# func _update_active_character() -> void:
# 	for portrait in _portraits.values():
# 		portrait.scale = Vector2(0.4, 0.4)
# 	var character = _combat.get_active_character()
# 	_portraits[character].scale = Vector2.ONE
