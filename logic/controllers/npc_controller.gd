# CharacterController specific for NPCs
class_name NpcController
extends CharacterController

func _process(delta) -> void:
	super._process(delta)
	if circle_needs_update:
		if hovered:
			if character.is_enemy:
				update_selection_circle(true, Vector3(0.612, 0.098, 0.098), 0.45)
			else:
				update_selection_circle(true, Vector3(0.369, 0.592, 0.263), 0.45)
		else:
			update_selection_circle(false)
		circle_needs_update = false
