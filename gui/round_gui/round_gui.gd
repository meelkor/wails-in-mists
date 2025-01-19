class_name RoundGui
extends Control

const CombatTopBar = preload("res://gui/combat_top_bar/combat_top_bar.gd")

const ParticipantPortrait = preload("res://gui/participant_portrait/participant_portrait.gd")

var di := DI.new(self)

@onready var _combat := di.inject(Combat) as Combat

@onready var _combat_top_bar := %CombatTopBar as CombatTopBar
@onready var _box_left := %BoxLeft as HBoxContainer
@onready var _box_center := %BoxCenter as HBoxContainer
@onready var _box_right := %BoxRight as HBoxContainer


func _ready() -> void:
	_update_portraits()
	_update_bar_size()
	_combat.state.changed.connect(_update_portraits)
	_combat.combat_participants_changed.connect(_update_bar_size)


## Update the top bar size whenever participant number changes
func _update_bar_size() -> void:
	# todo: read somehow from portrait
	const PORTRAIT_WIDTH := 150
	const MARGIN := 4
	var count := _combat.state.participant_order.size()
	var width := (count - 1) * PORTRAIT_WIDTH + PORTRAIT_WIDTH + (count - 1) * MARGIN
	_combat_top_bar.set_width(width)


## Clear all existing portrait nodes and create then according to current
## combat state.
##
## todo: introduce some animation between states
##  - either slowly scale from right to center and from center to left
##  - or fade into transparent while moving left and fading from transparent
##    from right at the same time
func _update_portraits() -> void:
	Utils.Nodes.clear_children(_box_center)
	Utils.Nodes.clear_children(_box_left)
	Utils.Nodes.clear_children(_box_right)

	for i in range(_combat.state.participant_order.size()):
		var character := _combat.state.participant_order[i]
		var ParticipantPortraitScene := preload("res://gui/participant_portrait/participant_portrait.tscn")
		var portrait := ParticipantPortraitScene.instantiate() as ParticipantPortrait
		portrait.character = character
		portrait.active = i == _combat.state.turn_number
		if portrait.active:
			_box_center.add_child(portrait)
		else:
			if i < _combat.state.turn_number:
				_box_left.add_child(portrait)
			else:
				_box_right.add_child(portrait)
