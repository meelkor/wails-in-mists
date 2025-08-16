## Script for terrain3d nodes which e.g. handles emitting clicks and generating
## navmesh since both are very Terrain3D specific.
##
## Also displays my dumbass circle/line decals since Terrain3d doesn't support
## multiple shader passes.
class_name LevelTerrain3D
extends Terrain3D

var di := DI.new(self)

@onready var _level_camera := di.inject(LevelCamera) as LevelCamera
@onready var _navigation := di.inject(Navigation) as Navigation
@onready var _controlled_characters := di.inject(ControlledCharacters) as ControlledCharacters
@onready var _spawned_npcs := di.inject(SpawnedNpcs) as SpawnedNpcs

const decals_material = preload("res://rust/src/fow/decals_postprocessing.tres")

signal input_event(e: InputEvent, world_position: Vector3)

func _ready() -> void:
	global.rebake_navigation_mesh_request.connect(_on_nav_obstacles_changed)


func _unhandled_input(e: InputEvent) -> void:
	var m_event := e as InputEventMouse
	if m_event:
		var camera := _level_camera
		var origin := camera.project_ray_origin(m_event.position)
		var end := origin + camera.project_ray_normal(m_event.position) * 10000
		var query := PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		query.collision_mask = Utils.get_collision_layer("terrain") | Utils.get_collision_layer("characters") | Utils.get_collision_layer("interactable")
		var result := get_world_3d().direct_space_state.intersect_ray(query)
		if result and (result["collider"] == self or result["collider"] is StaticBody3D):
			var pos := result["position"] as Vector3
			input_event.emit(e, pos)


## Implementation for that Terrain#snap_down abstract method.
func snap_down(pos: Vector3) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(pos, pos + Vector3.DOWN * 5.)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = Utils.get_collision_layer("terrain")
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result:
		return result["position"]
	else:
		return Vector3.INF


func _on_nav_obstacles_changed() -> void:
	if _navigation:
		var char_positions := PackedVector3Array()
		var characters: Array[GameCharacter]
		characters.append_array(_controlled_characters.get_characters())
		characters.append_array(_spawned_npcs.get_characters())
		characters = characters.filter(func (ch: GameCharacter) -> bool: return ch.action.static_obstacle)
		char_positions.resize(characters.size())
		for i in range(characters.size()):
			char_positions[i] = characters[i].position
		_navigation.cut_holes(char_positions)


## Create instance of Terrain which proxies signals/methods from the provided
## source, so we can provide Terrain3D subclass instance which implements all
## the necessary methods/signals as the Terrain interface class.
func __create_proxy() -> Terrain:
	return LevelTerrain3DTerrainProxy.new(self)


## Class introduced to workaround gdscript's lack of interfaces or traits.
class LevelTerrain3DTerrainProxy:
	extends Terrain

	var _terrain3d: LevelTerrain3D


	func _init(src: LevelTerrain3D) -> void:
		_terrain3d = src
		_terrain3d.input_event.connect(input_event.emit)


	func snap_down(pos: Vector3) -> Vector3:
		return _terrain3d.snap_down(pos)
