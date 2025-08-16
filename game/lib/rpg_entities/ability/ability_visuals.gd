## Defines visual appearance of something that the ability spawns for short
## moment and the animation during the "casting" (e.g. magic casting, weapon
## slash...)
##
## This class shouldn't handle long lasting effects of buffs or the effect
## caused on target character. That should be handled by the AbilityEffect
## class.
class_name AbilityVisuals
extends Resource


func execute(exec: AbilityExecution, ctrl: CharacterController, ability: Ability, target: AbilityTarget) -> void:
	@warning_ignore("redundant_await")
	await _on_execute(exec, ctrl, ability, target)


func end(ctrl: CharacterController) -> void:
	_on_remove(ctrl)


## Abstract method that should handle all the animations, effect scene spawning
## etc and propagate the progress through the execution instance.
func _on_execute(_exec: AbilityExecution, _ctrl: CharacterController, _ability: Ability, _target: AbilityTarget) -> void:
	assert(false, "AbilityVisuals#_on_execute not implemented")


## Abstract method called when the ability process ends. Should clean up any
## spawned projectiles and make sure everything gets unreferenced.
func _on_remove(_ctrl: CharacterController) -> void:
	pass
