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

	for character in _combat.state.participant_order:
		var ParticipantPortraitScene = preload("res://gui/participant_portrait/participant_portrait.tscn") as PackedScene
		var portrait = ParticipantPortraitScene.instantiate()
		portrait.character = character
		$HBoxContainer.add_child(portrait)
		_portraits[character] = portrait
