# Structure containing all character's abilities which should be provided as
# controller to nodes that may want to display them / cast them
class_name AbilityCaster
extends RefCounted

signal ability_used(character: GameCharacter, ability: Ability)

var character: GameCharacter

func _init():
	pass
