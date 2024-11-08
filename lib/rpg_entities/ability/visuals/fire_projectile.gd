class_name FireProjectileVisuals
extends AbilityVisuals

const FIRE_PROJECTILE_SCENE = preload("res://lib/rpg_entities/ability/visuals/fire_projectile_scene.gd")

@export var projectile: PackedScene

func execute(ctrl: CharacterController, _ability: Ability, target: AbilityTarget) -> AbilityVisuals.Execution:
	var scn := projectile.instantiate() as FIRE_PROJECTILE_SCENE
	assert(scn.get_script() == FIRE_PROJECTILE_SCENE)
	ctrl.look_at(target.get_world_position())
	var offset := Vector3.UP * 1.2
	scn.position += Vector3.FORWARD * 0.5 + offset
	scn.target = target
	scn.offset = offset
	ctrl.ability_effect_slot.mount(scn)
	return scn.execution
