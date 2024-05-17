# Node which computes ability effect based on game's current state. Should be
# provided via DI for nodes that handle casting abilities.
class_name AbilityResolver
extends Node

var di = DI.new(self)

@onready var combat: Combat = di.inject(Combat)

### Public ###

func execute(request: AbilityRequest):
	var new_action = CharacterCasting.new(request.ability, request.target)
	request.caster.action = new_action
	await new_action.hit
	request.ability.effect.effect_script.execute(request)
