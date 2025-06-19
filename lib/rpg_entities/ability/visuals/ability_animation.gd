## Ability visuals for abilities which just play animation on caster and
## optionally display display scene
class_name AnimationVisuals
extends AbilityVisuals

## Animation to start
@export var animation_name: CharacterController.OneShotAnimation

## If true, weapon is drawn first
@export var requires_weapon: bool

## If true, caster looks in the direction of ability target before running the
## animation
@export var target_aware: bool


func _on_execute(exec: AbilityExecution, ctrl: CharacterController, _ability: Ability, target: AbilityTarget) -> void:
	if requires_weapon:
		await ctrl.draw_weapon()
	if target_aware:
		var target_position := target.get_world_position(true)
		ctrl.look_at_standing(target_position)
	ctrl.fire_animation(animation_name)
	# todo: accessing those animation related signals is kinda pain... rethink
	await ctrl.wait_for_animation_signal(ctrl.character_scene.hit_connected)
	exec.hit.emit()
	await ctrl.wait_for_animation_signal(ctrl.character_scene.animation_tree.animation_finished)
	# todo: implement some channel in the GameCharacter for informing that the
	# character should start defending itself (run the animation)
	exec.completed.emit()
