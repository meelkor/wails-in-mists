# CharacterController specific for playable characters further extending the
# CharacterController's functionality.

class_name PlayerController
extends CharacterController

func _ready():
	super._ready()
	$SightArea.body_exited.connect(_on_sight_exit)


func _process(delta: float) -> void:
	super._process(delta)

	if circle_needs_update:
		if character.selected:
			# todo: define colors as constants somwhere pls
			update_selection_circle(true, Vector3(0.094,0.384,0.655), 1.0)
		elif hovered:
			update_selection_circle(true, Vector3(0.239,0.451,0.651), 0.4)
		else:
			update_selection_circle(false)
		circle_needs_update = false

	for visible_node in $SightArea.get_overlapping_bodies():
		# fixme: all npcs are visible at start (but it's hard to tell since
		# they are behind fow)
		visible_node.visible = true


### Private ###

# whenever anything cullable (collision group 1) leaves, set visible to false.
# If someone else sees it, it will be re-set to true again in its own process.
func _on_sight_exit(char_ctrl_or_cullable):
	char_ctrl_or_cullable.visible = false
