## Node which computes ability effect based on game's current state. Should be
## provided via DI for nodes that handle casting abilities.
##
## TODO: should also display the hit result on UI
class_name AbilityResolver
extends Node

var di := DI.new(self)

@onready var combat: Combat = di.inject(Combat)


## Start the ability execution (setting the correct character action) and
## resolve the result (hit/miss, combat damage etc)
func execute(request: AbilityRequest) -> AbilityExecution:
	var execution := AbilityExecution.new()
	var new_action := CharacterCasting.new(request.ability, request.target, execution)
	request.caster.action = new_action
	execution.hit.connect(request.ability.effect.execute.bind(request))
	return execution
