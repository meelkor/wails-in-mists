@icon("res://class_icons/base_level.svg")
class_name BaseLevel
extends Node

@export var level_name = "Base Level"

@export var terrain: Array[CollisionObject3D] = []

@export var player_spawn: PlayerSpawn

@onready var _navigation_regions = find_children("", "NavigationRegion3D") as Array[NavigationRegion3D]
@onready var _level_gui: LevelGui = $LevelGui
@onready var _controlled_characters: ControlledCharacters = $ControlledCharacters

# Refernce to the ongoing combat if any
var _current_combat: Combat

# Reference to the RoundGui that is dynamically created on the start of the
# combat and removed after the combat is done
var _round_gui: RoundGui

### Public ###

func spawn_playable_characters(characters: Array[PlayableCharacter]):
	$ControlledCharacters.spawn(characters, player_spawn)
	$RustyFow.setup(_create_terrain_aabb())
	$ControlledCharacters.position_changed.connect(_on_controlled_characters_position_changed)
	$LevelGui.set_characters(characters)

### Lifecycle ###

func _ready() -> void:
	assert(len(terrain) > 0, "BaseLevel is missing terrain path")
	assert(player_spawn, "BaseLevel is missing player spawn path")
	assert(len(_navigation_regions) > 0, "Level has no nvagiation region for pathfinding")

	global.message_log().system("Entered %s" % level_name)

	$LevelCamera.move_to(player_spawn.position)
	$LevelCamera.rect_selected.connect(_handle_camera_rect_selection)
	global.rebake_navigation_mesh_request.connect(_on_nav_obstacles_changed)
	_on_nav_obstacles_changed()
	_add_terrain_shader_pass()
	_spawn_npc_controllers()

	_controlled_characters.character_clicked.connect(_handle_pc_click)
	_level_gui.character_selected.connect(_handle_pc_click)

	for terrain_object in terrain:
		terrain_object.input_event.connect(_on_terrain_input_event)

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
	_update_round_gui()

# Iterate over all spawned characters and set their action depending on given
# combat state. Should be called at the beginning of the combat to normalize
# all characters, so they stop walking etc.
func _set_default_combat_actions_to_all(combat: Combat) -> void:
	var all_npcs = _get_spawned_npcs()
	var all_pcs = _controlled_characters.get_characters()
	for npc in all_npcs:
		if combat.has_npc(npc):
			npc.action = CharacterIdleCombat.new()
		else:
			npc.action = CharacterIdle.new()
	for pc in all_pcs:
		pc.action = CharacterIdleCombat.new()
		pc.selected = false

# Handler of clicking on playable character - be it portrait or model
func _handle_pc_click(character: PlayableCharacter, type: PlayableCharacter.InteractionType) -> void:
	if not _current_combat:
		if type == PlayableCharacter.InteractionType.SELECT_ALONE:
			var characters = _controlled_characters.get_characters()
			for pc in characters:
				pc.selected = character == pc
		elif type == PlayableCharacter.InteractionType.SELECT_MULTI:
			character.selected = true

# Select characters
func _handle_camera_rect_selection(rect: Rect2):
	for character in _controlled_characters.get_characters():
		character.selected = rect.has_point($LevelCamera.unproject_position(character.position))

# Create or remove RoundGui child scene depending whether in combat or not
func _update_round_gui():
	if _current_combat and not _round_gui:
		var RoundGuiScene = load("res://logic/combat/round_gui/round_gui.tscn") as PackedScene
		var round_gui = RoundGuiScene.instantiate() as RoundGui
		round_gui.combat = _current_combat
		add_child(round_gui)
	elif not _current_combat and _round_gui:
		remove_child(_round_gui)
		_round_gui.queue_free()

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

# Event handler for terrain inputs
func _on_terrain_input_event(_camera, event: InputEvent, input_pos: Vector3, _normal, _idx):
	if not _current_combat:
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
