## Generic class all three levels of weapon types inherit, so we can have
## properties accepting all tree
class_name __CombatCategory
extends Resource

## Main visible name and identifier of the entity
@export var name: String

## Optional icon depending
##
## todo: still dunno whether "melee combat" or "fencing" should have its own
## icon, or only l3 types like "Short sword"
@export var icon: Texture2D

## "Technical" description explaining what to expect from gameplay point of view
@export var description: String

## Optional flavor text for tooltip
@export var lore: String


## Represents number representing level in weapon type tree. Should be constant
## per subclass. Needs to be method since we can't nicely override variables in
## subclasses.
func get_level() -> int:
	assert(false, "__CombatCategory level getter must be implemented")
	return 0


func make_tooltip_content() -> RichTooltip.Content:
	return RichTooltip.create_generic_tooltip(name, description)
