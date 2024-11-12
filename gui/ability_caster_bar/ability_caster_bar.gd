# fixme: I don't want this class to be named, but preload the script in
# level_gui.gd completely breaks the game throwing nonsensical type error
class_name AbilityCasterBar
extends VBoxContainer

var di := DI.new(self)

@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)

@onready var _combat: Combat = di.inject(Combat)

@onready var _button_grid := %AbilityButtons as GridContainer
@onready var _turn_actions_label := %TurnActionsLabel as Label

var caster: PlayableCharacter


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
	caster.changed.connect(_update_buttons)


func _process(_d: float) -> void:
	if _combat.active:
		var actions_strings := _combat.state.turn_actions.map(func (action: CombatAction) -> String: return "%s [%s]" % [action.attribute.name if action.attribute else "Neutral", "x" if action.used else "  "])
		var actions_text := "  |  ".join(actions_strings)
		var steps_count := absi(ceili(_combat.state.steps))
		_turn_actions_label.text = "%s     | Steps: %s" % [actions_text, steps_count]
	else:
		_turn_actions_label.text = ""


## Connect caster bar buttons to current caster
func _update_buttons() -> void:
	# todo: how are things like cooldown gonna be propagated here and how often
	# will buttons be updated
	var all_disabled := _combat.active and not _combat.is_free()
	for i in range(0, _button_grid.get_child_count()):
		var btn := _button_grid.get_child(i) as SlotButton
		btn.disabled = all_disabled


func _run_button_action(i: int) -> void:
	var ability_process := AbilityRequest.new()
	ability_process.caster = caster
	ability_process.ability = caster.bar_abilities.get_entity(i)
	ability_process.combat = di.inject(Combat)
	_controlled_characters.ability_casted.emit(ability_process)
