## Node which computes ability effect based on game's current state. Should be
## provided via DI for nodes that handle casting abilities.
##
## TODO: should also display the hit result on UI
class_name AbilityResolver
extends Node

var di := DI.new(self)

## Area3D used for finding aoe collisions
##
## todo: correctly the casting (projectile or static position) should be
## probably node with its own collider/area fired by character controller and
## then just checks colliders within at the hit moment... I should've made
## abilities into nodes...
##
## todo: and if not ^ it still sucks that those areas and shapes are defined
## twice - once here and once in target select controls
@onready var _aoe := $Area3D as Area3D
@onready var _aoe_shape := $Area3D/Area3DSphere as CollisionShape3D


## Start the ability execution (setting the correct character action) and
## resolve the result (hit/miss, _combat damage etc)
func execute(request: AbilityRequest) -> AbilityExecution:
	var execution := AbilityExecution.new()
	var new_action := CharacterCasting.new(request.ability, request.target, execution)
	request.caster.action = new_action
	_aoe.monitoring = true
	execution.hit.connect(func () -> void:
		match request.ability.target_type:
			Ability.TargetType.AOE, Ability.TargetType.AOE_BOUND:
				(_aoe_shape.shape as SphereShape3D).radius = request.ability.aoe_size
				if request.target.is_none():
					_aoe.global_position = request.caster.position
				else:
					_aoe.global_position = request.target.get_world_position(false)
				# related to todo above, fml
				await get_tree().physics_frame
				await get_tree().physics_frame
				var characters := _aoe.get_overlapping_bodies()\
					.map(func (ctrl: CharacterController) -> GameCharacter: return ctrl.character)\
					.filter(func (c: GameCharacter) -> bool: return request.is_targetable(c))
				request.resolved_targets.assign(characters)
			Ability.TargetType.SINGLE:
				request.resolved_targets = [request.target.get_character()]
			Ability.TargetType.SELF:
				request.resolved_targets = [request.caster]
		request.ability.effect.execute(request)
	)

	return execution
