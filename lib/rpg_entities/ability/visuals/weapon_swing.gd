extends AbilityVisuals


func _on_execute(exec: AbilityExecution, ctrl: CharacterController, _ability: Ability, target: AbilityTarget) -> void:
	_run_animation.call_deferred(ctrl, target, exec)


func _run_animation(ctrl: CharacterController, target: AbilityTarget, ex: AbilityExecution) -> void:
	var target_char := target.get_character()
	# todo: implement animated look at in the character controller
	ctrl.look_at(target_char.position)
	# todo: run swing animation once it exists
	ex.hit.emit()
	# todo: implement some channel in the GameCharacter for informing that the
	# character should start defending itself (run the animation)
	ex.completed.emit()
