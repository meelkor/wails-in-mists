class_name ControlledCharacters
extends Node

# Signal emitting shortly after any of the controlled character's position
# changes. Can be used to run enemy logic, fow update etc.
signal position_changed(positions)

var position_changed_needs_update = true
var time_since_update = 0

func _ready():
	var camera: LevelCamera = get_viewport().get_camera_3d()
	camera.connect("rect_selected", _on_terrain_controller_rect_selected)
	update_goal_vectors()

func _process(delta: float) -> void:
	# FIXME: Hacky because I don't wanna create timer in this component, which
	# should only contain chracters
	# Also I am still not even sure whether I'm not overusing signals. Maybe
	# It would be better to just iterate over children and check
	# position_changed flag on in 100ms or something
	if position_changed_needs_update and time_since_update > 0.1:
		position_changed_needs_update = false
		var positions: Array[Vector3] = []
		# fml: https://github.com/godotengine/godot/issues/72566 (I am one more
		# step closer to switching to rust)
		positions.assign(get_children().map(func (ch): return ch.position))
		position_changed.emit(positions)
		time_since_update = 0
	else:
		time_since_update += delta

# Add a new controlled character under this controller.
#
# This method should be always used instead of calling add_child directly
func spawn(characters: Array[PlayableCharacter], spawn_node: PlayerSpawn):
	var spawn_position = spawn_node.position
	for character in characters:
		var ctrl = preload("res://logic/controllers/player_controller.tscn").instantiate()
		ctrl.setup(character)
		add_child(ctrl)
		ctrl.position_changed.connect(func(_pos): position_changed_needs_update = true)
		ctrl.action_changed.connect(_on_character_action_changed)
		ctrl.clicked.connect(_select_single)
		ctrl.position = spawn_position
		spawn_position -= Vector3(0.8, 0, 0.8)

func _on_terrain_controller_rect_selected(rect: Rect2):
	var children = get_children()
	for child in children:
		if child is CharacterController:
			var pos = child.get_position_on_screen()
			child.character.selected = rect.has_point(pos)

func _select_single(character: PlayableCharacter):
	var children = get_children()
	for child in children:
		# TODO: rewrite so ctrls are never passed like this and instead
		# PlayableCharacter instances and their signals are used
		if child is CharacterController:
			child.character.selected = character == child.character

func walk_selected_to(pos: Vector3):
	var controllers = get_children()
	var sample_controller: CharacterController = controllers[0] as CharacterController
	if sample_controller:
		var direction = pos.direction_to(sample_controller.position)
		var offset = 0
		for controller in controllers:
			if controller.character.selected:
				controller.walk_to(pos + offset * direction)
				offset += 1

func _on_character_action_changed(action):
	# todo: all of this is ugly, but I still dunno who should be actually
	# responsible for the character action vs terrain decals.
	#
	# fixme: when goal changes (e.g. another character stopped at that goal
	# first) the decal is not updated...
	if action is CharacterWalking:
		await action.goal_computed
	update_goal_vectors()

func update_goal_vectors():
	var controllers = get_children()
	var goals = []
	goals.resize(4)
	for i in range(0, 4):
		if i < controllers.size() && controllers[i].action is CharacterWalking:
			goals[i] = controllers[i].action.goal
		else:
			goals[i] = Vector3(-20, -20, -20)
	for body in get_parent().terrain:
		for mesh in body.find_children("", "MeshInstance3D"):
			if mesh is MeshInstance3D:
				var mat = mesh.get_active_material(0) as Material
				if mat.next_pass is ShaderMaterial:
					mat.next_pass.set_shader_parameter("goal_positions", goals)
