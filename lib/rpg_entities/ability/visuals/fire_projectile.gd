class_name FireProjectileVisuals
extends AbilityVisuals

const FireProjectileScene = preload("res://lib/rpg_entities/ability/visuals/fire_projectile_scene.gd")

@export var projectile: PackedScene


func _on_execute(exec: AbilityExecution, ctrl: CharacterController, _ability: Ability, target: AbilityTarget) -> void:
	await ctrl.fire_animation(CharacterController.OneShotAnimation.MELEE_1H_ATTACK)
	var scn := projectile.instantiate() as FireProjectileScene
	assert(scn.get_script() == FireProjectileScene)
	ctrl.look_at(target.get_world_position())
	var offset := Vector3.UP * 1.2
	scn.position += Vector3.FORWARD * 0.5 + offset
	scn.target = target
	scn.offset = offset
	scn.execution = exec
	ctrl.ability_effect_slot.mount(scn)
