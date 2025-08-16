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
	if target_aware:
		var target_position := target.get_world_position(true)
		ctrl.look_at_standing(target_position)
	if requires_weapon:
		ctrl.update_animation(CharacterController.AnimationState.COMBAT)
		await ctrl.draw_weapon()
	ctrl.fire_animation(animation_name, false)
	# todo: nope, ditch the is_character/get_character calls and instead do
	# something like for character in Level.resolve_target_characters(target)
	if target.is_character():
		ctrl.character_scene.pre_connected.connect(
			func () -> void: target.get_character().get_controller().defend_against(ctrl.character),
			ConnectFlags.CONNECT_ONE_SHOT
		)
	# todo: accessing those animation related signals is kinda pain... rethink
	await ctrl.wait_for_animation_signal(ctrl.character_scene.hit_connected)
	exec.hit.emit()
	await ctrl.wait_for_animation_signal(ctrl.character_scene.animation_tree.animation_finished)
	exec.completed.emit()
