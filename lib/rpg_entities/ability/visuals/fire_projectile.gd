## Ability visuals for abilities with which character throws given projectile
## scene onto target.
class_name FireProjectileVisuals
extends AbilityVisuals

const FireProjectileScene = preload("res://lib/rpg_entities/ability/visuals/fire_projectile_scene.gd")

## Scene to throw as a projectile that then flies to the target position
@export var projectile: PackedScene

## Projectile's speed m/s. The actual speed is then eased
@export var speed: float = 12.0


func _on_execute(exec: AbilityExecution, ctrl: CharacterController, _ability: Ability, target: AbilityTarget) -> void:
	ctrl.fire_animation(CharacterController.OneShotAnimation.MELEE_1H_ATTACK, false)
	await ctrl.wait_for_animation_signal(ctrl.character_scene.casting_started)
	var scn := projectile.instantiate() as FireProjectileScene
	assert(scn.get_script() == FireProjectileScene)
	ctrl.look_at_standing(target.get_world_position(true))
	var attachment := BoneAttachment3D.new()
	# todo: mirror animation depending on free hands
	attachment.bone_name = AttachableBone.HAND_R
	attachment.add_child(scn)
	ctrl.character_scene.skeleton.add_child(attachment)
	scn.fire_animation(FireProjectileScene.ProjectileAnimation.SPAWN)
	await ctrl.wait_for_animation_signal(ctrl.character_scene.casting_ended)
	# fixme: ugh, ugly accessing the base level, where to put the projectile?
	# Return it since the effect should always have at most one scene that
	# handles multiple projectiles...
	var base_level := ctrl.di.inject(BaseLevel) as BaseLevel
	var destination := target.get_world_position(true)
	scn.reparent(base_level, true)
	Utils.Nodes.remove_self(attachment)
	scn.fire_animation(FireProjectileScene.ProjectileAnimation.FLY)
	var tw := ctrl.create_tween()
	var duration := scn.global_position.distance_to(destination) / speed
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_method(_tween_to_target.bind(scn, scn.global_position, target), 0., 1., duration)
	await tw.finished
	scn.fire_animation(FireProjectileScene.ProjectileAnimation.HIT)
	exec.hit.emit()
	exec.completed.emit()


func _tween_to_target(progress: float, scn: Node3D, from: Vector3, target: AbilityTarget) -> void:
	scn.global_position = from.lerp(target.get_world_position(true), progress)
