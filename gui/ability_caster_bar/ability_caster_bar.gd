extends GridContainer

var di = DI.new(self)

@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)

@onready var _combat: Combat = di.inject(Combat)

var caster: AbilityCaster:
	set (val):
		caster = val
		caster.abilities_changed.connect(_update_buttons)
		if is_inside_tree():
			_update_buttons()

var _computed = Computed.new()

### Lifecycle ###

func _ready() -> void:
	for i in range(get_child_count()):
		var child_btn = get_child(i) as Button
		child_btn.pressed.connect(_run_button_action.bind(i))
	if caster:
		_update_buttons()


func _process(_d) -> void:
	# dumbass idea, make into signal I guess, but I still do not know how the
	# "in middle of casting -> not free" is gonna be computed
	var combat_free = _combat.is_free()
	if _computed.changed("combat_free", combat_free):
		_update_buttons()


### Private ###


func _update_actions() -> void:
	pass
	#if _combat.active and _combat.get_active_character() is PlayableCharacter:
	#	var action_bar = _action_bar_slot.get_or_instantiate()
	#	action_bar.update(_combat.actions, _combat.steps and stufff)
	#else:
	#	_action_bar_slot.clear()


func _update_buttons() -> void:
	var combat_free = _combat.is_free()
	var abilities = caster.get_buttons()
	for i in range(0, get_child_count()):
		var btn = get_child(i) as Button
		if i < abilities.size():
			var ability = abilities[i]
			btn.text = ability.name
			btn.disabled = !combat_free
		else:
			btn.text = ""
			btn.disabled = true

func _run_button_action(i: int):
	var ability_process = AbilityRequest.new()
	ability_process.caster = caster.character
	ability_process.ability = caster.get_buttons()[i]
	ability_process.combat = di.inject(Combat)
	_controlled_characters.ability_casted.emit(ability_process)
