# Node which computes ability effect based on game's current state. Should be
# provided via DI for nodes that handle casting abilities.
class_name AbilityResolver
extends Node

var di = DI.new(self)

@onready var combat: Combat = di.inject(Combat)

### Public ###

func execute(request: AbilityRequest):
	var new_action = CharacterCasting.new(request.ability, request.target)
	# todo: we do not know which animation should play after ability animation
	# is done playing but before the ability hits...
	request.caster.action = new_action
	await new_action.hit
	request.ability.effect.effect_script.execute(request)
