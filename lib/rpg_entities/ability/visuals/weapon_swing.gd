extends AbilityVisuals


func execute(ctrl: CharacterController, _ability: Ability, target: AbilityTarget) -> AbilityVisuals.Execution:
	var ex := AbilityVisuals.Execution.new()
	_run_animation.call_deferred(ctrl, target, ex)
	return ex


func _run_animation(ctrl: CharacterController, target: AbilityTarget, ex: AbilityVisuals.Execution) -> void:
	var target_char := target.get_character()
	# todo: implement animated look at in the character controller
	ctrl.look_at(target_char.position)
	# todo: run swing animation once it exists
	ex.hit.emit()
	# todo: implement some channel in the GameCharacter for informing that the
	# character should start defending itself (run the animation)
	ex.completed.emit()
