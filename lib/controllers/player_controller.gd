## CharacterController specific for playable characters further extending the
## CharacterController's functionality.
class_name PlayerController
extends CharacterController

var pc: PlayableCharacter:
	get: return character


func _ready() -> void:
	super._ready()
	sight_area.body_exited.connect(_on_sight_exit)
	character.died_in_combat.connect(_handle_death)
	character.changed.connect(_on_character_changed)


func _process(delta: float) -> void:
	super._process(delta)
	for visible_node in sight_area.get_overlapping_bodies():
		visible_node.visible = true


## whenever anything cullable (collision group 1) leaves, set visible to false.
## If someone else sees it, it will be re-set to true again in its own process.
func _on_sight_exit(char_ctrl_or_cullable: Node3D) -> void:
	char_ctrl_or_cullable.visible = false


func _handle_death(src: Vector3) -> void:
	# todo: or use rigged animation for this?
	_activate_ragdoll((global_position - src).normalized() * 1.5)


func _on_character_changed() -> void:
	if character.alive and _ragdoll_on:
		# todo: somehow animation standing up
		character_scene.simulator.physical_bones_stop_simulation()
		character_scene.animation_tree.active = true
