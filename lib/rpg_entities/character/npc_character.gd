# Represents player controllable character. Be it player's character or a
# companion.
extends GameCharacter
class_name NpcCharacter

var is_enemy: bool


func get_color() -> Vector3:
	return Utils.Vector.rgb(Config.Palette.ENEMY if is_enemy else Config.Palette.NPC)


func _to_string() -> String:
	return "<NpcCharacter:%s#%s>" % [name, get_instance_id()]
