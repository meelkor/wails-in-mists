extends AbilityVisuals


func _on_execute(exec: AbilityExecution, ctrl: CharacterController, _ability: Ability, target: AbilityTarget) -> void:
	await ctrl.draw_weapon()
	var target_char := target.get_character()
	ctrl.look_at_standing(target_char.position)
	ctrl.fire_animation(CharacterController.OneShotAnimation.MELEE_1H_ATTACK)
	# todo: accessing those animation related signals is kinda pain... rethink
	await ctrl.wait_for_animation_signal(ctrl.character_scene.hit_connected)
	exec.hit.emit()
	await ctrl.wait_for_animation_signal(ctrl.character_scene.animation_tree.animation_finished)
	# todo: implement some channel in the GameCharacter for informing that the
	# character should start defending itself (run the animation)
	exec.completed.emit()
