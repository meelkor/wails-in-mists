# Represents player controllable character. Be it player's character or a
# companion.
extends GameCharacter
class_name PlayableCharacter

# Enums containing ways player might interact with playable character (be it
# model or portrait)
enum InteractionType {
	# usually left click
	SELECT_MULTI,
	# usually left click with shift
	SELECT_ALONE,
	# usually right click
	CONTEXT,
}

signal selected_changed(character: PlayableCharacter, new_selected: bool)

@export var portrait: String = "res://textures_ui/portraits/PLACEHOLDER_STOLEN.png"

@export var selected: bool = false:
	get:
		return selected
	set(v):
		selected = v
		selected_changed.emit(self, v)
