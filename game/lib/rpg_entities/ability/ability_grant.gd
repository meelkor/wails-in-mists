## Wrapper around ability available by some talent or equipment, with details
## whether the grant is allowed and reason if it's not.
class_name AbilityGrant
extends RefCounted

var ability: Ability

var available: bool

## todo: maybe condition for the grant should be defined inside the grant and
## the reason text should be then generated based on those conditions
var reason: String


func _init(i_ability: Ability, i_available: bool = true) -> void:
	ability = i_ability
	available = i_available
