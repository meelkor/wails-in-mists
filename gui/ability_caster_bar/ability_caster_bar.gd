extends VBoxContainer

var di = DI.new(self)

@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)

@onready var _combat: Combat = di.inject(Combat)

@onready var _button_grid = %AbilityButtons
@onready var _turn_actions_label: Label = %TurnActionsLabel

var caster: GameCharacter

### Lifecycle ###

func _ready() -> void:
	for i in range(_button_grid.get_child_count()):
		var child_btn = _button_grid.get_child(i) as Button
		child_btn.pressed.connect(_run_button_action.bind(i))
	if caster:
		_update_buttons()


func _process(_d) -> void:
	# todo: do on combat state change
	_update_buttons()
	if _combat.active:
		var actions_strings = _combat.state.turn_actions.map(func (action): return "%s [%s]" % [action.attribute.name if action.attribute else "Neutral", "x" if action.used else "  "])
		var actions_text = "  |  ".join(actions_strings)
		var steps_count = abs(ceil(_combat.state.steps))
		_turn_actions_label.text = "%s     | Steps: %s" % [actions_text, steps_count]
	else:
		_turn_actions_label.text = ""


### Private ###


func _update_actions() -> void:
	pass
	#if _combat.active and _combat.get_active_character() is PlayableCharacter:
	#	var action_bar = _action_bar_slot.get_or_instantiate()
	#	action_bar.update(_combat.actions, _combat.steps and stufff)
	#else:
	#	_action_bar_slot.clear()


func _update_buttons() -> void:
	var all_disabled := _combat.active and not _combat.is_free()
	for i in range(0, _button_grid.get_child_count()):
		var btn := _button_grid.get_child(i) as Button
		if i < caster.abilities.size():
			var ability := caster.abilities.get_entity(i)
			btn.text = ability.name
			btn.disabled = all_disabled || _combat.active and not _combat.state.has_unused_actions(ability.required_actions)
		else:
			btn.text = ""
			btn.disabled = true


func _run_button_action(i: int):
	var ability_process = AbilityRequest.new()
	ability_process.caster = caster
	ability_process.ability = caster.abilities.get_entity(i)
	ability_process.combat = di.inject(Combat)
	_controlled_characters.ability_casted.emit(ability_process)
