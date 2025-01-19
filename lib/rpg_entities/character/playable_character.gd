## Represents player controllable character. Be it player's character or a
## companion.
class_name PlayableCharacter
extends GameCharacter

@export var selected: bool = false:
	get:
		return selected
	set(v):
		if selected != v:
			selected = v
			emit_changed()

## Contains abilities the player has put onto the bar for this character. Not
## to be mistaken with .abilities which include all available abilities that
## can be accessed view the character dialog.
@export var bar_abilities := BarAbilities.new(abilities)

## All talent packs the character has available and can "equip"
@export var available_talents := TalentList.new()


func get_controller() -> PlayerController:
	return _controller


func get_color() -> Color:
	return Config.Palette.PC


## Fill ability bar with all available abilities
##
## TODO: decide how to do "automatically assign new abilitites" and "assign
## initial abilities on game start"
func fill_ability_bar() -> void:
	for ability in abilities.get_all():
		bar_abilities.add_entity(ability)


func _to_string() -> String:
	return "<PlayableCharacter:%s#%s>" % [name, get_instance_id()]
