## CharacterController specific for playable characters further extending the
## CharacterController's functionality.
class_name PlayerController
extends CharacterController

var pc: PlayableCharacter:
	get: return character


func _ready() -> void:
	super._ready()
	sight_area.body_exited.connect(_on_sight_exit)


func _process(delta: float) -> void:
	super._process(delta)
	for visible_node in sight_area.get_overlapping_bodies():
		visible_node.visible = true


func _update_selection_circle() -> void:
	if pc.selected:
		# todo: define colors as constants somwhere pls
		update_selection_circle(true, Vector3(0.094,0.384,0.655), 1.0)
	elif pc.targeted:
		update_selection_circle(true, Vector3(0.094,0.384,0.655), 1.0, 0.5)
	elif pc.hovered:
		update_selection_circle(true, Vector3(0.239,0.451,0.651), 0.4)
	else:
		update_selection_circle(false)


## whenever anything cullable (collision group 1) leaves, set visible to false.
## If someone else sees it, it will be re-set to true again in its own process.
func _on_sight_exit(char_ctrl_or_cullable: Node3D) -> void:
	char_ctrl_or_cullable.visible = false
