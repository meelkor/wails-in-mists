## Ability visuals for abilities which just play animation on caster and
## optionally display display scene
class_name AnimationVisuals
extends AbilityVisuals

@export var animation_name: CharacterController.OneShotAnimation


func _on_execute(exec: AbilityExecution, ctrl: CharacterController, _ability: Ability, _target: AbilityTarget) -> void:
	ctrl.fire_animation(animation_name)
	await ctrl.wait_for_animation_signal(ctrl.character_scene.casting_ended)
	exec.hit.emit()
	exec.completed.emit()
