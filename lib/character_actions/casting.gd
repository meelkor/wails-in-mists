class_name CharacterCasting
extends CharacterAction

signal hit()

# Character / Vector3 or null
var _target: AbilityTarget

var _ability: Ability

### Lifecycle ###

func _init(ability: Ability, target: AbilityTarget) -> void:
	_target = target
	_ability = ability

func start(ctrl: CharacterController) -> void:
	var execution := _ability.visuals.execute(ctrl, _ability, _target)
	await execution.hit
	hit.emit()
	await execution.completed
	ctrl.ability_effect_slot.clear()
