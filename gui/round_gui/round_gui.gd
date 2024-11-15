class_name RoundGui
extends Control

const ParticipantPortrait = preload("res://gui/participant_portrait/participant_portrait.gd")

var di := DI.new(self)

@onready var _combat := di.inject(Combat) as Combat

## Reference to the portrain scenes for each combat participant
var _portraits: Dictionary[GameCharacter, ParticipantPortrait]


func _ready() -> void:
	_update_portraits()
	_combat.combat_participants_changed.connect(_update_portraits)


func _update_portraits() -> void:
	for child in $HBoxContainer.get_children():
		child.queue_free()

	for character in _combat.state.participant_order:
		var ParticipantPortraitScene := preload("res://gui/participant_portrait/participant_portrait.tscn")
		var portrait := ParticipantPortraitScene.instantiate() as ParticipantPortrait
		portrait.character = character
		$HBoxContainer.add_child(portrait)
		_portraits[character] = portrait
