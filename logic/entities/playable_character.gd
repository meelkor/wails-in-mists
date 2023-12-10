# Represents player controllable character. Be it player's character or a
# companion.
extends GameCharacter
class_name PlayableCharacter

signal selected_changed(character: PlayableCharacter, new_selected: bool)

@export var portrait: String

@export var selected: bool = false:
	get:
		return selected
	set(v):
		selected = v
		selected_changed.emit(self, v)

func _init(new_name: String):
	super(new_name)
	portrait = "res://textures_ui/portraits/PLACEHOLDER_STOLEN.png"
