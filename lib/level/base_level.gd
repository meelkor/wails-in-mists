@icon("res://resources/class_icons/base_level.svg")
class_name BaseLevel
extends Node3D

@export var level_name = "Base Level"

# Static bodies of the level's terrain. Need to be set for FOW, decals,  etc.
# to work as expected.
@export var terrain_bodies: Array[StaticBody3D] = []

@export var player_spawn: PlayerSpawn

@onready var _navigation_regions = find_children("", "NavigationRegion3D") as Array[NavigationRegion3D]

# Wrapped terrain bodies with some conveinient accessors
var _terrain: TerrainWrapper

# Slot for (Combat|Exploration)Controller that is currently active.
var _logic_ctrl_slot = NodeSlot.new(self, "LogicController")

var di = DI.new(self, {
	ControlledCharacters: ^"./ControlledCharacters",
	# TODO: make into node
	TerrainWrapper: func (): return _terrain,
	LevelGui: ^"./LevelGui",
	Combat: ^"./Combat",
	LevelCamera: ^"./LevelCamera",
	SpawnedNpcs: ^"./SpawnedNpcs",
	AbilityResolver: ^"./AbilityResolver",
})

### Public ###

func spawn_playable_characters(characters: Array[PlayableCharacter]):
	$ControlledCharacters.spawn(characters, player_spawn)
	$RustyFow.setup(_create_terrain_aabb())
	$ControlledCharacters.position_changed.connect(_on_controlled_characters_position_changed)
	$LevelGui.set_characters(characters)

### Lifecycle ###

func _ready() -> void:
	assert(len(terrain_bodies) > 0, "BaseLevel is missing terrain path")
	assert(player_spawn, "BaseLevel is missing player spawn path")
	assert(len(_navigation_regions) > 0, "Level has no nvagiation region for pathfinding")

	_terrain = TerrainWrapper.new(terrain_bodies)

	global.message_log().system("Entered %s" % level_name)

	$LevelCamera.move_to(player_spawn.position)
	global.rebake_navigation_mesh_request.connect(_on_nav_obstacles_changed)
	_on_nav_obstacles_changed()

	# Find all terrain meshes and give them extra shader pass which takes care
	# of displaying our "decals"
	_terrain.set_next_pass_material(preload("res://materials/terrain_projections.tres"))
	_spawn_npc_controllers()
	_update_logic_controller()
	# todo: disable equipment swapping... or make it read from the character
	# object?
	$Combat.combat_participants_changed.connect(_update_logic_controller)

func _process(_d: float) -> void:
	# Provide character mask to postprocessing so we can render characters
	# behind objects.
	#
	# TODO: the mask is currently one frame behind which is ugly while zooming
	# for example. no idea how to solve it tho
	var img = $MaskViewport.get_texture().get_image()
	var tex = ImageTexture.create_from_image(img)
	$Screen.mesh.material.set_shader_parameter("character_mask", tex)

### Private ###

func _spawn_npc_controllers() -> void:
	var spawners = find_children("", "NpcSpawner")
	for spawner in spawners:
		if spawner is NpcSpawner:
			$SpawnedNpcs.spawn(spawner.create_controller())

# Update currently active LogicController depending of the combat state
func _update_logic_controller():
	if $Combat.active and not _logic_ctrl_slot.node is CombatController:
		var CombatControllerScene = load("res://lib/combat/combat_controller.tscn") as PackedScene
		var controller = CombatControllerScene.instantiate() as CombatController
		_logic_ctrl_slot.mount(controller)
	elif not $Combat.active and not _logic_ctrl_slot.node is ExplorationController:
		var ExplorationControllerScene = load("res://lib/exploration/exploration_controller.tscn") as PackedScene
		var controller = ExplorationControllerScene.instantiate() as ExplorationController
		_logic_ctrl_slot.mount(controller)

# Create AABB of all terrain meshes combined baking in their 3D translation
func _create_terrain_aabb() -> AABB:
	# todo: use the terrain value instead of iterating of ALL meshes
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
