## Script that should be used for root node of (for now) humanoid model scenes
## imported from gltf and have the paths set correctly, so we then know which
## mesh is what (body, eyes etc.)
@tool
class_name CharacterScene
extends Node3D

## Signal emitted by animations when in position where the weapon should change
## attachment bones depending on combat/peace state.
signal weapon_changed()

## Signal emitted by animations when in position where the weapon reaches its
## potential target before the character.
signal hit_connected()

## Signal emitted by animations when the ability animation is about to cause
## effect. At this time target character should switch to defensive animation.
signal pre_connected()

## Signal emitted by animations when in position where the casted projectile
## should start appearing.
signal casting_started()

## Signal emitted by animations when in position where the casted projectile
## should be "thrown" by the character
signal casting_ended()

@export var body: MeshInstance3D

@export var animation_tree: CharacterAnimationTree

@export var collision_shape: CollisionShape3D

@export var skeleton: Skeleton3D

@export var simulator: PhysicalBoneSimulator3D

## Can be optionally set to use to generate portraits with. Otherwise default
## camera near model's "head" is used.
@export var portrait_camera: Camera3D

## Whether animation_tree contains specific animation for combat movement/idle
var supports_combat_animations: bool:
	get:
		return animation_tree.idle_combat_animation && animation_tree.walk_combat_animation


## Emit wrapper for animation keyframe
func _weapon_changed() -> void:
	weapon_changed.emit()


## Emit wrapper for animation keyframe
func _hit_connected() -> void:
	hit_connected.emit()


## Emit wrapper for animation keyframe
func _casting_started() -> void:
	casting_started.emit()


## Emit wrapper for animation keyframe
func _casting_ended() -> void:
	casting_ended.emit()


## Emit wrapper for animation keyframe
func _pre_connected() -> void:
	pre_connected.emit()
