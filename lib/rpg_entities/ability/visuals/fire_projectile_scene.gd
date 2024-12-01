## Script which should be used (or its subclass) by the root node of any
## projectile scene we want to fire using the FireProjectile ability visuals,
## as it contains some common public methods which should work the same for all
## such abilities
extends Node3D

## Animation player needs to be set in the scene and the player may provide
## following animations available: `spawn`, `fly`, `hit`. If any of
## those animation doesn't exist, the phase is skipped.
@export var animation_player: AnimationPlayer


func fire_animation(animation: ProjectileAnimation) -> Signal:
	var animation_name := (ProjectileAnimation.find_key(animation) as String).to_lower()
	if animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
		return animation_player.animation_finished
	elif animation == ProjectileAnimation.HIT:
		_despawn.call_deferred()
	return get_tree().create_timer(0).timeout


## Helper to be used by hit animation
func _despawn() -> void:
	Utils.Nodes.remove_self(self)


enum ProjectileAnimation {
	SPAWN,
	FLY,
	HIT,
}
