## Ability visuals for abilities with which character throws given projectile
## scene onto target.
class_name FireProjectileVisuals
extends AbilityVisuals

const FireProjectileScene = preload("res://lib/rpg_entities/ability/visuals/fire_projectile_scene.gd")

@export var projectile: PackedScene

@export var speed: float = 12.0


func _on_execute(exec: AbilityExecution, ctrl: CharacterController, _ability: Ability, target: AbilityTarget) -> void:
	ctrl.fire_animation(CharacterController.OneShotAnimation.MELEE_1H_ATTACK)
	await ctrl.wait_for_animation_signal(ctrl.character_scene.casting_started)
	var scn := projectile.instantiate() as FireProjectileScene
	assert(scn.get_script() == FireProjectileScene)
	ctrl.look_at(target.get_world_position())
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = AttachableBone.HAND_R
	attachment.add_child(scn)
	ctrl.character_scene.skeleton.add_child(attachment)
	scn.fire_animation(FireProjectileScene.ProjectileAnimation.SPAWN)
	await ctrl.wait_for_animation_signal(ctrl.character_scene.casting_ended)
	# fixme: ugh, ugly accessing the base level, where to put the projectile?
	# Return it? ugh. Remove the visuals abstraction and have throw_projectile
	# on character controller?
	var base_level := ctrl.di.inject(BaseLevel) as BaseLevel
	var destination := target.get_world_position() + Vector3.UP * 1.4
	scn.reparent(base_level, true)
	Utils.Nodes.remove_self(attachment)
	scn.fire_animation(FireProjectileScene.ProjectileAnimation.FLY)
	var tw := ctrl.create_tween()
	var duration := scn.global_position.distance_to(destination) / speed
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(scn, "global_position", destination, duration)
	await tw.finished
	scn.fire_animation(FireProjectileScene.ProjectileAnimation.HIT)
	exec.hit.emit()
