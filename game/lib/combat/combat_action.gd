## Represents single combat action which player may (or NPC) may use to perform
## abilities or to convert them into movement points.
class_name CombatAction
extends Resource


## Which attribut granted action. Abilities may require combat actions of
## specific attributes.
## May be null for "neutral" actions.
@export var attribute: CharacterAttribute

## Whether character already used up this action for some ability
@export var used: bool = false

func _init(attr: CharacterAttribute) -> void:
	attribute = attr
