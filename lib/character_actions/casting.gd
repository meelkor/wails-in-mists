class_name CharacterCasting
extends CharacterAction

## Character / Vector3 or null
var _target: AbilityTarget

var _ability: Ability

var _execution: AbilityExecution

## Reference to the visuals whose execution we await, so we can propagate
## action end event.
var _started_visuals: AbilityVisuals


func is_free() -> bool:
	return false


func _init(ability: Ability, target: AbilityTarget, exec: AbilityExecution) -> void:
	_target = target
	_ability = ability
	_execution = exec


func start(ctrl: CharacterController) -> void:
	# hacky solution so we own the visuals can have their own state, but also
	# nicely configurable in resource editor
	_started_visuals = _ability.visuals.duplicate()
	_started_visuals.execute(_execution, ctrl, _ability, _target)


func end(ctrl: CharacterController) -> void:
	if _started_visuals:
		_started_visuals.end(ctrl)
