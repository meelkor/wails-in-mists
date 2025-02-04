## Represents player controllable character. Be it player's character or a
## companion.
extends GameCharacter
class_name NpcCharacter

## Character's dialogue started when interacted with the character. This
## dialogue may be overriden by dialogue set on the character's spawner, so the
## same character in different levels can have completely different dialogues.
## Usually only used for friendly NPCs.
@export var dialogue: DialogueGraph


func get_color() -> Color:
	return Config.Palette.ENEMY if enemy else Config.Palette.NPC


func get_controller() -> NpcController:
	return _controller


func _to_string() -> String:
	return "<NpcCharacter:%s#%s>" % [name, get_instance_id()]
