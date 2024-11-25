## Script which should be used (or its subclass) by the root node of any
## projectile scene we want to fire using the FireProjectile ability visuals,
## as it contains some common public methods which should work the same for all
## such abilities
extends Node3D

const ANIMATION_SPAWN = "spawn"
const ANIMATION_FLY = "fly"
const ANIMATION_HIT = "hit"

var di := DI.new(self)

## Projectile speed in m/s
@export var speed: float = 6

## Animation player needs to be set in the scene and the player may provide
## following animations available: `spawn`, `fly`, `hit`. If any of
## those animation doesn't exist, the phase is skipped.
@export var animation_player: AnimationPlayer

## Should be set by whoever created the scene. The scene will fly to the given
## target.
var target: AbilityTarget

## Should be set by whoever created the scene so the progress can be
## propagated.
var execution: AbilityExecution

## Offset from the actual target position where the projectile should fly to
var offset: Vector3

var _flying: bool = false


func _ready() -> void:
	# todo: Handle the spawning animation here or in the AbilityVisuals
	# insatnce that spawns this?
	if animation_player.has_animation(ANIMATION_SPAWN):
		animation_player.play(ANIMATION_SPAWN)
		await animation_player.animation_finished
	animation_player.play(ANIMATION_FLY)
	_flying = true


func _process(delta: float) -> void:
	if _flying:
		var target_pos := target.get_world_position() + offset
		var frame_movement := delta * speed
		var dist_to_target := global_position.distance_to(target_pos) - 0.02
		if frame_movement > dist_to_target:
			global_position = target_pos
			_flying = false
			execution.hit.emit()
			if animation_player.has_animation(ANIMATION_HIT):
				animation_player.play(ANIMATION_HIT)
				await animation_player.animation_finished
			execution.completed.emit()
		else:
			global_position = global_position.move_toward(target_pos, delta * speed)
