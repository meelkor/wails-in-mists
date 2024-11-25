class_name CharacterCasting
extends CharacterAction

## Character / Vector3 or null
var _target: AbilityTarget

var _ability: Ability

var _execution: AbilityExecution

## Reference to the visuals whose execution we await. It's only used in the
## start method, but if we store it there locally, it doesn't get freed when
## action is not longer referenced and thus the execution continues, even
## though the action is no longer referenced. Dunno why exactly tbh
var _started_visuals: AbilityVisuals


func _init(ability: Ability, target: AbilityTarget, exec: AbilityExecution) -> void:
	_target = target
	_ability = ability
	_execution = exec


func start(ctrl: CharacterController) -> void:
	await ctrl.draw_weapon()
	# hacky solution so we own the visuals instance and thus this action
	# instance can be freed when no longer has any reference
	_started_visuals = _ability.visuals.duplicate()
	_started_visuals.execute(_execution, ctrl, _ability, _target)
	await _execution.hit
	await _execution.completed
	ctrl.ability_effect_slot.clear()
