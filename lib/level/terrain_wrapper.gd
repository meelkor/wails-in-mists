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
	for existing_mat in get_materials():
		assert(not existing_mat.next_pass)
		existing_mat.next_pass = material


# Get all materials used for the meshes in the terrain bodies
func get_materials() -> Array[Material]:
	var materials: Array[Material] = []
	for mesh in get_meshes():
		materials.append(mesh.get_active_material(0))
	return materials


# Get all meshes in the bodies
func get_meshes() -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	for body in _bodies:
		meshes.append_array(body.find_children("", "MeshInstance3D"))
	return meshes

# Set shader paramer for the second pass in all materials used for terrains.
func set_next_pass_shader_parameter(param_name: String, value: Variant):
	# todo: store reference to the shader material, since it's shared among all
	# meshes
	for mat in get_materials():
		if mat.next_pass is ShaderMaterial:
			mat.next_pass.set_shader_parameter(param_name, value)

### Lifecycle ###

func _init(bodies: Array[StaticBody3D]):
	_bodies = bodies
	for body in bodies:
		body.input_event.connect(func (_cam, event, input_pos, _normal, _idx): input_event.emit(event, input_pos))


