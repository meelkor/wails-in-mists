## Base class for every overworld level, which takes care of finding various
## nodes in the level, creating post-processing nodes (fow / outlines) etc. and
## provides all of that to child nodes via DI. Also spawns characters so the
## level actually starts.
@icon("res://resources/class_icons/base_level.svg")
class_name BaseLevel
extends Node3D

## Actually created since we need to access the exported nodepath which isn't
## assigned on _init yet.
var di: DI

@onready var _game_instance := di.inject(GameInstance) as GameInstance

## Signal emitted usually by lootable mesh so the current controller/controls
## node can react appropriately
##
## todo: I hate that we need to send lootablemesh rather than just lootable,
## but we need to know its location...
signal loot_requested(lootable_mesh: LootableMesh)

## Lootable mesh hover is also handled by current controller. Lootable by
## itself doesn't visbly react to the player's input.
signal lootable_hovered(lootable_mesh: LootableMesh, state: bool)

signal cutscene_changed(active: bool)

@export var level_name := "Base Level"

@export var player_spawn: PlayerSpawn

## Path to node which implements all methods defined in the Terrain class.
@export var terrain_node: NodePath

## When cutscene is active, player controls and events such as enemy detection
## should be disabled until it changes to false.
@export var cutscene_active: bool = false:
	set(v):
		cutscene_active = v
		cutscene_changed.emit(v)


@export_node_path("Navigation") var navigation_node: NodePath

@onready var _outline_viewport := $OutlineViewport as SubViewport
@onready var _camera := $LevelCamera as LevelCamera
@onready var _screen := $Screen as MeshInstance3D
@onready var _combat := $Combat as Combat

## Slot for (Combat|Exploration)Controller that is currently active.
var _logic_ctrl_slot := NodeSlot.new(self, "LogicController")

var _characters_to_start: Dictionary[GameCharacter, bool] = {}


## Report that given character's action changed and should be started at the
## end of frame
##
## todo: rather than controller passing characters to base_level, this should
## be handled by node that stores all spawned character => merge
## ControlledCharacters and SpawnedNpcs into SpawnedCharacters which just holds
## references to playable/npcs in different arrays for ease of iteration, but
## all characters will be inside one node, which will make many things easier
func enqueue_character_action(character: GameCharacter) -> void:
	_characters_to_start.set(character, true)


func _enter_tree() -> void:
	di = DI.new(self, {
		BaseLevel: ^"./",
		ControlledCharacters: ^"./ControlledCharacters",
		Terrain: terrain_node,
		LevelGui: ^"./LevelGui",
		DragDropHost: ^"./DragDropHost",
		Combat: ^"./Combat",
		LevelCamera: ^"./LevelCamera",
		SpawnedNpcs: ^"./SpawnedNpcs",
		AbilityResolver: ^"./AbilityResolver",
		TooltipSpawner: ^"./LevelGui/TooltipSpawner",
		Navigation: navigation_node,
	})


func _ready() -> void:
	assert(player_spawn, "BaseLevel is missing player spawn path")

	if not Engine.is_editor_hint():
		_screen.visible = true

	global.message_log().system("Entered %s" % level_name)

	_camera.move_to(player_spawn.position)

	_spawn_playable_characters(_game_instance.state.characters)

	_spawn_npc_controllers()
	_update_logic_controller()
	# todo: disable equipment swapping... or make it read from the character
	# object?
	($Combat as Combat).combat_participants_changed.connect(_update_logic_controller)
	($Combat as Combat).ended.connect(_update_logic_controller)

	global.rebake_navigation_mesh()


func _process(_d: float) -> void:
	var material := (_screen.mesh as QuadMesh).material as ShaderMaterial
	var outline_tex := _outline_viewport.get_texture()
	material.set_shader_parameter("outline_mask", outline_tex)
	if _characters_to_start.size() > 0:
		global.rebake_navigation_mesh()
		for chara in _characters_to_start:
			chara.action.start(chara.get_controller())
		_characters_to_start.clear()


func _spawn_npc_controllers() -> void:
	var spawners := find_children("", "NpcSpawner")
	for spawner: NpcSpawner in spawners:
		if spawner is NpcSpawner and spawner.is_visible_in_tree():
			($SpawnedNpcs as SpawnedNpcs).spawn(spawner.create_controller())


func _spawn_playable_characters(characters: Array[PlayableCharacter]) -> void:
	($ControlledCharacters as ControlledCharacters).spawn(characters, player_spawn)
	($ControlledCharacters as ControlledCharacters).position_changed.connect(_on_controlled_characters_position_changed)
	($LevelGui as LevelGui).set_characters(characters)


## Update currently active LogicController depending of the combat state
func _update_logic_controller() -> void:
	if _combat.active and not _logic_ctrl_slot.node is CombatController:
		var CombatControllerScene := load("res://lib/combat/combat_controller.tscn") as PackedScene
		var controller := CombatControllerScene.instantiate() as CombatController
		_logic_ctrl_slot.mount(controller)
	elif not _combat.active and not _logic_ctrl_slot.node is ExplorationController:
		var ExplorationControllerScene := load("res://lib/exploration/exploration_controller.tscn") as PackedScene
		var controller := ExplorationControllerScene.instantiate() as ExplorationController
		_logic_ctrl_slot.mount(controller)


## Create AABB of all terrain meshes combined baking in their 3D translation
func _create_terrain_aabb() -> AABB:
	# todo: use the terrain value instead of iterating of ALL meshes
	var nodes := find_children("", "MeshInstance3D")
	var terrain_aabb: AABB
	for node: MeshInstance3D in nodes:
		var naabb := node.get_aabb()
		# todo: also factor in rotation and scale to get the actual new aabb
		var translated_aabb := AABB(naabb.position + node.global_position, naabb.size)
		if !terrain_aabb:
			terrain_aabb = translated_aabb
		else:
			terrain_aabb = terrain_aabb.merge(translated_aabb)
	return terrain_aabb


func _on_controlled_characters_position_changed(positions: Array[Vector3]) -> void:
	($RustyFow as RustyFow).update(positions)
