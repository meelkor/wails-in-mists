class_name ControlledCharacters
extends Node

# Signal emitting shortly after any of the controlled character's position
# changes. Can be used to run enemy logic, fow update etc.
signal position_changed(positions)

var position_changed_needs_update = true

func _ready():
	var camera: LevelCamera = get_viewport().get_camera_3d()
	camera.connect("rect_selected", _on_terrain_controller_rect_selected)

	var level = get_node("../") as BaseLevel
	level.connect("terrain_clicked", _on_terrain_clicked)

	update_goal_vectors()

func _process(_delta: float) -> void:
	# FIXME: Hacky because I don't wanna create timer in this component, which
	# should only contain chracters
	# Also I am still not even sure whether I'm not overusing signals. Maybe
	# It would be better to just iterate over children and check
	# position_changed flag on in 100ms or something
	if position_changed_needs_update:
		position_changed_needs_update = false
		var positions: Array[Vector3] = []
		# fml: https://github.com/godotengine/godot/issues/72566 (I am one more
		# step closer to switching to rust)
		positions.assign(get_children().map(func (ch): return ch.position))
		position_changed.emit(positions)

# Add a new controlled character under this controller.
#
# This method should be always used instead of calling add_child directly
func add_character(character: CharacterController):
	add_child(character)
	character.position_changed.connect(func(_pos): position_changed_needs_update = true)
	character.action_changed.connect(_on_character_action_changed)

func _on_terrain_controller_rect_selected(rect: Rect2):
	var children = get_children()
	for child in children:
		if child is CharacterController:
			var pos = child.get_position_on_screen()
			child.character.selected = rect.has_point(pos)

# TODO: rewrite so ctrls are never passed like this and instead
# PlayableCharacter instances and their signals are used
func select_single(character: PlayableCharacter):
	var children = get_children()
	for child in children:
		if child is CharacterController:
			child.character.selected = character == child.character

func _on_terrain_clicked(pos: Vector3):
	var controllers = get_children()
	var sample_controller: CharacterController = controllers[0] as CharacterController
	if sample_controller:
		var direction = pos.direction_to(sample_controller.position)
		var offset = 0
		for controller in controllers:
			if controller.character.selected:
				controller.walk_to(pos + offset * direction)
				offset += 1

func _on_character_action_changed(_action):
	update_goal_vectors()

func update_goal_vectors():
	var controllers = get_children()
	var terrain_bodies = get_tree().get_nodes_in_group(KnownGroups.TERRAIN)
	var goals = []
	goals.resize(4)
	for i in range(0, 4):
		if i < controllers.size() && controllers[i].action is CharacterWalking:
			goals[i] = controllers[i].action.goal
		else:
			goals[i] = Vector3(-20, -20, -20)
	for body in terrain_bodies:
		for mesh in body.find_children("", "MeshInstance3D"):
			if mesh is MeshInstance3D:
				var mat = mesh.get_active_material(0) as Material
				if mat.next_pass is ShaderMaterial:
					mat.next_pass.set_shader_parameter("goal_positions", goals)
