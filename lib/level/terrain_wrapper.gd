# Conveinience class which simplifies access to the terrain body meshes of the
# level, so all of this doesn't need to be covered in the BaseLevel class
#
# This class very much assumes that each Mesh has material with single pass by
# default and that we want to add ShaderMaterial as second pass. Once that
# changes, we'll need to rewrite this.
class_name TerrainWrapper
extends RefCounted

# Simple wrapper around all the bodies input events
signal input_event(event: InputEvent, input_pos: Vector3)

var _bodies: Array[StaticBody3D]

### Public ###

# Set given material and the next pass to all meshes inside the terrain bodies.
# Assumes the mesh materials do not have next_pass yet.
func set_next_pass_material(material: Material) -> void:
	for mesh_instance in get_meshes():
		MaterialUtils.set_last_pass(mesh_instance, material)

# Get all meshes in the bodies
func get_meshes() -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	for body in _bodies:
		meshes.append_array(body.find_children("", "MeshInstance3D"))
	return meshes

const MAX_PATH_POINTS = 6

## Display given path (discarding y component though) on the _terrain as a
## dashed line. Only color_len meters are in color, the rest is dimmed.
func project_path_to_terrain(path: PackedVector3Array, color_len: float = 0, moved: float = 0) -> void:
	var material = preload("res://materials/terrain_projections.tres")
	if path.size() > 1:
		var line_path = Utils.Path.path3d_to_path2d(path, MAX_PATH_POINTS)
		material.set_shader_parameter("line_vertices", line_path)
		material.set_shader_parameter("color_length", color_len)
		material.set_shader_parameter("moved", moved)
	else:
		var empty_path = PackedVector2Array()
		empty_path.resize(MAX_PATH_POINTS)
		empty_path.fill(Vector2(-1, -1))
		material.set_shader_parameter("line_vertices", empty_path)

### Lifecycle ###

func _init(bodies: Array[StaticBody3D]):
	_bodies = bodies
	for body in bodies:
		body.input_event.connect(func (_cam, event, input_pos, _normal, _idx): input_event.emit(event, input_pos))
