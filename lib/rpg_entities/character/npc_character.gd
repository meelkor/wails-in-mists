# Represents player controllable character. Be it player's character or a
# companion.
extends GameCharacter
class_name NpcCharacter

var is_enemy: bool


func get_color() -> Vector3:
	return Vector3(0.612, 0.098, 0.098) if is_enemy else Vector3(0.369, 0.592, 0.263)
