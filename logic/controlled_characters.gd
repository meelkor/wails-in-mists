class_name ControlledCharacters
extends Node

# Signal emitting shortly after any of the controlled character's position
# changes. Can be used to run enemy logic, fow update etc.
signal position_changed(positions)

var position_changed_needs_update = false
var time_since_pos_update_signal: float = 0

func _ready():
	var camera: LevelCamera = get_parent().get_node("LevelCamera")
	camera.connect("rect_selected", _on_terrain_controller_rect_selected)

	var terrain = get_node("../TerrainController") as TerrainController
	terrain.connect("terrain_clicked", _on_terrain_clicked)

	update_goal_vectors()

func _process(delta: float) -> void:
	# FIXME: Hacky because I don't wanna create timer in this component, which
	# should only contain chracters
	# Also I am still not even sure whether I'm not overusing signals. Maybe
	# It would be better to just iterate over children and check
	# position_changed flag on in 100ms or something
	time_since_pos_update_signal += delta
	if position_changed_needs_update:
		position_changed_needs_update = false
		time_since_pos_update_signal = 0
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
			child.selected = rect.has_point(pos)

func select_single(ctrl: CharacterController):
	var children = get_children()
	for child in children:
		if child is CharacterController:
			child.selected = ctrl == child

func _on_terrain_clicked(pos: Vector3):
	var controllers = get_children()
	var sample_controller: CharacterController = controllers[0] as CharacterController
	if sample_controller:
		var direction = pos.direction_to(sample_controller.position)
		var offset = 0
		for controller in controllers:
			if controller.selected:
				controller.walk_to(pos + offset * direction)
				offset += 1

func _on_character_action_changed(_action):
	update_goal_vectors()

func update_goal_vectors():
	var controllers = get_children()
	# FIXME: The way we are querying the material can break easily with
	# more diverse terrain meshes
	var terrain_meshes = get_tree().get_nodes_in_group("terrain")
	var goals = []
	goals.resize(4)
	for i in range(0, 4):
		if i < controllers.size() && controllers[i].action is CharacterWalking:
			goals[i] = controllers[i].action.goal
		else:
			goals[i] = Vector3(-20, -20, -20)
	for mesh in terrain_meshes:
		if mesh is MeshInstance3D:
			var mat = mesh.get_active_material(0) as Material
			var mp = mat.next_pass as ShaderMaterial
			mp.set_shader_parameter("goal_positions", goals)
