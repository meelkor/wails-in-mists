@icon("res://resources/class_icons/base_level.svg")
class_name BaseLevel
extends Node3D

@export var level_name = "Base Level"

# Static bodies of the level's terrain. Need to be set for FOW, decals,  etc.
# to work as expected.
@export var terrain_bodies: Array[StaticBody3D] = []

@export var player_spawn: PlayerSpawn

@onready var _navigation_regions = find_children("", "NavigationRegion3D") as Array[NavigationRegion3D]
@onready var _controlled_characters: ControlledCharacters = $ControlledCharacters

# Wrapped terrain bodies with some conveinient accessors
var _terrain: TerrainWrapper

# Refernce to the ongoing combat if any
var _current_combat: Combat

var _current_caster: AbilityCaster

# Slot for (Combat|Exploration)Controller that is currently active.
var _logic_ctrl_slot = NodeSlot.new(self, "LogicController")

var di = DI.new(self, {
	ControlledCharacters: ^"./ControlledCharacters",
	TerrainWrapper: func (): return _terrain,
	LevelGui: ^"./LevelGui"
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
	$LevelCamera.rect_selected.connect(_handle_camera_rect_selection)
	global.rebake_navigation_mesh_request.connect(_on_nav_obstacles_changed)
	_on_nav_obstacles_changed()

	# Find all terrain meshes and give them extra shader pass which takes care
	# of displaying our "decals"
	_terrain.set_next_pass_material(preload("res://materials/terrain_projections.tres"))
	_spawn_npc_controllers()

	_controlled_characters.selected_changed.connect(_handle_selected_characters_changed)
	_update_logic_controller()

### Private ###

func _spawn_npc_controllers() -> void:
	var spawners = find_children("", "NpcSpawner")
	for spawner in spawners:
		if spawner is NpcSpawner:
			var ctrl = spawner.create_controller()
			ctrl.initiated_combat.connect(_initiate_combat)
			$ControlledNpcs.add_child(ctrl)

func _initiate_combat(npc_participants: Array[NpcCharacter]) -> void:
	# todo: include who was noticed, but currently we are not propagating that
	# information => create some InitCombatData class or whatever
	global.message_log().system("Your party has been noticed by enemy")
	# todo: currently we are not listening to new participant additions to
	# combat correctly
	_current_combat = Combat.new(_controlled_characters.get_characters(), npc_participants)
	_set_default_combat_actions_to_all(_current_combat)
	_update_logic_controller()
	# todo: tell gui to disable equipment swapping... or make it read from the
	# character object?

# Iterate over all spawned characters and set their action depending on given
# combat state. Should be called at the beginning of the combat to normalize
# all characters, so they stop walking etc.
func _set_default_combat_actions_to_all(combat: Combat) -> void:
	var all_npcs = _get_spawned_npcs()
	var all_pcs = _controlled_characters.get_characters()
	for npc in all_npcs:
		if combat.has_npc(npc):
			npc.action = CharacterCombatWaiting.new()
		else:
			npc.action = CharacterIdle.new()
	for pc in all_pcs:
		pc.action = CharacterCombatWaiting.new()
		pc.selected = false

# Select characters
func _handle_camera_rect_selection(rect: Rect2):
	for character in _controlled_characters.get_characters():
		character.selected = rect.has_point($LevelCamera.unproject_position(character.position))

# Update currently active LogicController depending of the combat state
func _update_logic_controller():
	if _current_combat and not _logic_ctrl_slot.node is CombatController:
		var CombatControllerScene = load("res://lib/combat/combat_controller.tscn") as PackedScene
		var controller = CombatControllerScene.instantiate() as CombatController
		controller.combat = _current_combat
		_logic_ctrl_slot.mount(controller)
	elif not _current_combat and not _logic_ctrl_slot.node is ExplorationController:
		var ExplorationControllerScene = load("res://lib/exploration/exploration_controller.tscn") as PackedScene
		var controller = ExplorationControllerScene.instantiate() as ExplorationController
		_logic_ctrl_slot.mount(controller)

func _get_spawned_npcs() -> Array[NpcCharacter]:
	var npc_children = $ControlledNpcs.get_children()
	var npc_chars = npc_children.map(func (ctrl): return ctrl.character)
	var out: Array[NpcCharacter] = []
	out.assign(npc_chars)
	return out

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

func _handle_selected_characters_changed(chars: Array[PlayableCharacter]) -> void:
	if _current_caster:
		_current_caster = null
	if chars.size() == 1:
		_current_caster = AbilityCaster.new(chars[0], _current_combat)
		$LevelGui.display_ability_caster(_current_caster)
		_current_caster.ability_used.connect(_logic_ctrl_slot.node.start_ability_pipeline)
	else:
		$LevelGui.hide_ability_caster()
