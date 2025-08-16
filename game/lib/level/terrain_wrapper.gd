## Conveinience class which simplifies access to the terrain body meshes of the
## level, so all of this doesn't need to be covered in the BaseLevel class
##
## This class very much assumes that each Mesh has material with single pass by
## default and that we want to add ShaderMaterial as second pass. Once that
## changes, we'll need to rewrite this.
class_name TerrainWrapper
extends Terrain

const PROJECT_MATERIAL = preload("res://materials/terrain_projections.tres")

const MAX_PATH_POINTS = 6

## Static bodies of the level's terrain. Either this or terrain3d needs to be
## set for FOW, decals, etc. to work as expected.
@export var terrain_bodies: Array[StaticBody3D] = []


func _ready() -> void:
	for body in terrain_bodies:
		body.input_event.connect(func (_c: Node, event: InputEvent, pos: Vector3, _norm: Vector3, _idx: int) -> void: input_event.emit(event, pos))
	# Find all terrain meshes and give them extra shader pass which takes care
	# of displaying our "decals"
	for mesh_instance in _get_meshes():
		MaterialUtils.set_last_pass(mesh_instance, preload("res://materials/terrain_projections.tres"))


## Get all meshes in the bodies
func _get_meshes() -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	for body in terrain_bodies:
		meshes.append_array(body.find_children("", "MeshInstance3D"))
	return meshes
