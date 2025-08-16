class_name CharacterCasting
extends CharacterAction

## Character / Vector3 or null
var _target: AbilityTarget

var _ability: Ability

var _execution: AbilityExecution

## Reference to the visuals whose execution we await, so we can propagate
## action end event.
var _started_visuals: AbilityVisuals

signal _visuals_ended()


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
	await _started_visuals.execute(_execution, ctrl, _ability, _target)
	_started_visuals = null
	_visuals_ended.emit()


func end(ctrl: CharacterController) -> void:
	if _started_visuals:
		_started_visuals.end(ctrl)


## Set given action now or after ability animation ends if in progress.
##
## todo: this whole action shit is allll so fragile and has so many ways to
## break when e.g. combat starts while animation from combat that just ended is
## still running etc...
func equeue_action(action: CharacterAction) -> void:
	if _started_visuals:
		await _visuals_ended
	character.action = action
