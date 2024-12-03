## Script for terrain3d nodes which e.g. handles emitting clicks and generating
## navmesh since both are very Terrain3D specific.
##
## Also displays my dumbass circle/line decals since Terrain3d doesn't support
## multiple shader passes.
class_name LevelTerrain3D
extends Terrain3D

const MAX_LINE_SIZE = 6

var di := DI.new(self)

@onready var _level_camera := di.inject(LevelCamera) as LevelCamera

@onready var _base_level := di.inject(BaseLevel) as BaseLevel

signal input_event(e: InputEvent, world_position: Vector3)

func _ready() -> void:
	global.rebake_navigation_mesh_request.connect(_on_nav_obstacles_changed)


func _process(_delta: float) -> void:
	if TerrainCircle.changed:
		material.set_shader_param("circle_positions", TerrainCircle.get_positions_tex())
		material.set_shader_param("circle_colors", TerrainCircle.get_colors_tex())
		material.set_shader_param("circle_extras", TerrainCircle.get_extras_tex())
		material.set_shader_param("circle_count", TerrainCircle.get_count())
		TerrainCircle.changed = true


func _unhandled_input(e: InputEvent) -> void:
	var m_event := e as InputEventMouse
	if m_event:
		var camera := _level_camera
		var origin := camera.project_ray_origin(m_event.position)
		var end := origin + camera.project_ray_normal(m_event.position) * 10000
		var query := PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		query.collision_mask = Utils.get_collision_layer("terrain") | Utils.get_collision_layer("characters")
		var result := get_world_3d().direct_space_state.intersect_ray(query)
		if result and result["collider"] == self:
			var pos := result["position"] as Vector3
			input_event.emit(e, pos)


## Implementation of Terrain's method
func project_path_to_terrain(path: PackedVector3Array, color_len: float = 0, moved: float = 0) -> void:
	if path.size() > 1:
		var line_path_info := Utils.Path.path3d_to_path2d(path, MAX_LINE_SIZE)
		material.set_shader_param("line_vertices", line_path_info["path"])
		material.set_shader_param("line_size", line_path_info["size"])
		material.set_shader_param("color_length", color_len)
		material.set_shader_param("moved", moved)
	else:
		material.set_shader_param("line_size", 0)


func _on_nav_obstacles_changed() -> void:
	var nav := _base_level.navigation
	if nav:
		# wtf why do I need to call this for the new static colliders to take
		# effect. also why does debug navigation no longer work wtf
		nav.bake_navigation_mesh(false)
		var terrain_geometry := NavigationMeshSourceGeometryData3D.new()
		NavigationMeshGenerator.parse_source_geometry_data(nav.navigation_mesh, terrain_geometry, self)
		# todo: maybe call generate_nav_mesh_source_geometry once and create
		# static body and then only use standard flow... omg this may work
		# quite well
		terrain_geometry.add_faces(generate_nav_mesh_source_geometry(AABB()), Transform3D.IDENTITY)
		NavigationMeshGenerator.bake_from_source_geometry_data(nav.navigation_mesh, terrain_geometry)


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


	func project_path_to_terrain(path: PackedVector3Array, color_len: float = 0, moved: float = 0) -> void:
		_terrain3d.project_path_to_terrain(path, color_len, moved)
