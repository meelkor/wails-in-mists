class_name RoundGui
extends Control

var di = DI.new(self)

@onready var _combat = di.inject(Combat) as Combat

# Dict of GameCharacter => ParticipantPortrait
var _portraits: Dictionary

### Lifecycle ###

func _ready() -> void:
	_update_portraits()
	_combat.combat_participants_changed.connect(_update_portraits)

### Private ###

func _update_portraits():
	for child in $HBoxContainer.get_children():
		child.queue_free()

	for character in _combat._participant_order:
		var ParticipantPortraitScene = preload("res://gui/participant_portrait/participant_portrait.tscn") as PackedScene
		var portrait = ParticipantPortraitScene.instantiate()
		$HBoxContainer.add_child(portrait)
		_portraits[character] = portrait
	# combat.progressed.connect(_update_active_character)
	await get_tree().process_frame
	# _update_active_character()

# func _update_active_character() -> void:
# 	for portrait in _portraits.values():
# 		portrait.scale = Vector2(0.4, 0.4)
# 	var character = _combat.get_active_character()
# 	_portraits[character].scale = Vector2.ONE
# todo: create some CombatPortrait scene and use it instead of ^^^
