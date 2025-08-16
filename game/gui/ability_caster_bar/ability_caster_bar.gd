# fixme: I don't want this class to be named, but preload the script in
# level_gui.gd completely breaks the game throwing nonsensical type error
class_name AbilityCasterBar
extends VBoxContainer

const CombatActionCircle = preload("res://gui/combat_action_circle/combat_action_circle.gd")

var di := DI.new(self)

@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)
@onready var _combat: Combat = di.inject(Combat)

@export var caster: PlayableCharacter

@onready var _button_grid := %AbilityButtons as GridContainer
@onready var _combat_actions := %CombatActions as HBoxContainer
@onready var _steps_container := %StepsContainer as Container
@onready var _steps_label := %StepsLabel as Label

## References to the combat circle gui nodes mapped to the combat action from
## the combat for which it was created.
var _created_combat_actions: Dictionary[CombatAction, CombatActionCircle] = {}


func _ready() -> void:
	assert(caster, "Missing caster for ability caster bar")
	for i in range(0, _button_grid.get_child_count()):
		var btn := _button_grid.get_child(i) as SlotButton
		if btn:
			# slot_i needs to be set before container because the implementaion
			# is dumb
			btn.slot_i = i
			btn.container = caster.bar_abilities
			btn.used.connect(_run_button_action.bind(i))
	_update_buttons()
	_create_combat_actions()
	caster.changed.connect(_update_buttons)
	if _combat.active:
		_combat.state.changed.connect(_update_combat_actions)


## Create action circles if caster is the currently active character in combat
## and store references to them.
##
## This assumes a new AbilityCasterBar is created whenever turn begins, since
## it runs only once.
func _create_combat_actions() -> void:
	Utils.Nodes.clear_children(_combat_actions)
	_created_combat_actions = {}
	if _combat.active:
		var active_char := _combat.get_active_character()
		if active_char == caster:
			for action in _combat.state.turn_actions:
				var circle := preload("res://gui/combat_action_circle/combat_action_circle.tscn").instantiate() as CombatActionCircle
				circle.attribute = action.attribute
				_combat_actions.add_child(circle)
				_created_combat_actions[action] = circle


func _update_combat_actions() -> void:
	var steps_container_visible := false
	if _combat.active:
		for action in _created_combat_actions:
			var circle := _created_combat_actions[action]
			if action.attribute:
				circle.used = float(action.used)
			else:
				if _combat.state.steps > 0 and action.used:
					steps_container_visible = true
					_steps_label.text = str(int(ceilf(_combat.state.steps)))
					circle.used = 1. - _combat.state.steps / Ruleset.calculate_steps_per_action(caster)
				else:
					circle.used = float(action.used)
		_update_buttons()
	_steps_container.visible = steps_container_visible


## Connect caster bar buttons to current caster
func _update_buttons() -> void:
	# todo: how are things like cooldown gonna be propagated here and how often
	# will buttons be updated
	var all_disabled := _combat.active and not _combat.is_free()
	for i in range(0, _button_grid.get_child_count()):
		var has_actions := true
		var ability := caster.bar_abilities.get_entity(i) as Ability
		if ability:
			has_actions = ability.can_cast_with_attrs(_combat.get_turn_action_dict(caster))
		var btn := _button_grid.get_child(i) as SlotButton
		btn.disabled = all_disabled or not has_actions


func _run_button_action(i: int) -> void:
	var ability_process := AbilityRequest.new()
	ability_process.caster = caster
	ability_process.ability = caster.bar_abilities.get_entity(i)
	ability_process.combat = di.inject(Combat)
	_controlled_characters.ability_casted.emit(ability_process)
