extends GridContainer

var di = DI.new(self)

@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)

var caster: AbilityCaster

### Lifecycle ###

func _ready() -> void:
	_update_buttons()
	caster.abilities_changed.connect(_update_buttons)
	for i in range(get_child_count()):
		var child_btn = get_child(i) as Button
		child_btn.pressed.connect(_run_button_action.bind(i))

### Private ###

func _update_buttons() -> void:
	var abilities = caster.get_buttons()
	for i in range(0, get_child_count()):
		var btn = get_child(i) as Button
		if i < abilities.size():
			var ability = abilities[i]
			btn.text = ability.name
			btn.disabled = false
		else:
			btn.text = ""
			btn.disabled = true

func _run_button_action(i: int):
	var ability_process = AbilityRequest.new()
	ability_process.caster = caster.character
	ability_process.ability = caster.get_buttons()[i]
	ability_process.combat = di.inject(Combat)
	_controlled_characters.ability_casted.emit(ability_process)
