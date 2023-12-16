@icon("res://class_icons/base_level.svg")
class_name BaseLevel
extends Node

@export var level_name = "Base Level"

@export var terrain: Array[CollisionObject3D] = []

@export var player_spawn: PlayerSpawn

@onready var _navigation_regions = find_children("", "NavigationRegion3D") as Array[NavigationRegion3D]

func _ready() -> void:
	assert(len(terrain) > 0, "BaseLevel is missing terrain path")
	assert(player_spawn, "BaseLevel is missing player spawn path")
	assert(len(_navigation_regions) > 0, "Level has no nvagiation region for pathfinding")

	global.message_log().system("Entered %s" % level_name)

	$LevelCamera.move_to(player_spawn.position)
	global.rebake_navigation_mesh_request.connect(_on_nav_obstacles_changed)
	_on_nav_obstacles_changed()
	_add_terrain_shader_pass()
	_spawn_npc_controllers()

	for terrain_object in terrain:
		terrain_object.input_event.connect(_on_terrain_input_event)

func spawn_playable_characters(characters: Array[PlayableCharacter]):
	$ControlledCharacters.spawn(characters, player_spawn)
	$RustyFow.setup(_create_terrain_aabb())
	$ControlledCharacters.position_changed.connect(_on_controlled_characters_position_changed)
	$LevelGui.set_characters(characters)

func _spawn_npc_controllers() -> void:
	var spawners = find_children("", "NpcSpawner")
	for spawner in spawners:
		if spawner is NpcSpawner:
			$ControlledNpcs.add_child(spawner.create_controller())

# Create AABB of all terrain meshes combined baking in their 3D translation
func _create_terrain_aabb() -> AABB:
	var nodes = find_children("", "MeshInstance3D") as Array[MeshInstance3D]
	var terrain_aabb: AABB
	for node in nodes:
		var naabb = node.get_aabb()
		# todo: also factor in rotation and scale to get the actual new aabb
		var translated_aabb = AABB(naabb.position + node.global_position, naabb.size)
		if !terrain_aabb:
			terrain_aabb = translated_aabb
		else:
			terrain_aabb = terrain_aabb.merge(translated_aabb)
	return terrain_aabb

# Rebake the navigation mesh. It would be probably better to manually modify
# the polygons, but that sounds like a lot of work and this works somewhat fine
# so far.
func _on_nav_obstacles_changed():
	# Run on main thread so if the rebaking cause is initiated moviement the
	# first pathfinding is already on the updated mesh
	for region in _navigation_regions:
		region.bake_navigation_mesh(false)

func _on_controlled_characters_position_changed(positions) -> void:
	$RustyFow.update(positions)

# Event handler for terrain inputs
func _on_terrain_input_event(_camera, event: InputEvent, input_pos: Vector3, _normal, _idx):
	if event is InputEventMouseButton:
		if event.is_released() and  event.button_index == MOUSE_BUTTON_RIGHT:
			$ControlledCharacters.walk_selected_to(input_pos)

# Find all terrain meshes and give them extra shader pass which takes care of
# displaying our "decals"
func _add_terrain_shader_pass():
	for body in terrain:
		for mesh in body.find_children("", "MeshInstance3D"):
			if mesh is MeshInstance3D:
				var mat = mesh.get_active_material(0) as Material
				assert(not mat.next_pass)
				mat.next_pass = preload("res://materials/terrain_projections.tres")
