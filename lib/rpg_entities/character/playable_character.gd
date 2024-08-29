# Represents player controllable character. Be it player's character or a
# companion.
class_name PlayableCharacter
extends GameCharacter

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

@export var portrait: String = "res://resources/portraits/PLACEHOLDER_STOLEN.png"

@export var selected: bool = false:
	get:
		return selected
	set(v):
		if selected != v:
			selected = v
			selected_changed.emit(self, v)

## Contains abilities the player has put onto the bar for this character. Not
## to be mistaken with .abilities which include all available abilities that
## can be accessed view the character dialog.
##
## Todo: come up with some validation that character still has the ability
@export var bar_abilities := BarAbilities.new()


## Check whether player can freely move with this character (not paralyzed or
## anything)
func can_move_freely() -> bool:
	return true
