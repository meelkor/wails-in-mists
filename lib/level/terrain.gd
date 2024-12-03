## Abstract class with unified interface to work with the terrain, no matter
## how the terrain is actually rendered (static terrain vs. terrain3d since I
## am still not sure which I am gonna use in the end...)
class_name Terrain
extends Node

signal input_event(e: InputEvent, world_position: Vector3)


func project_path_to_terrain(_path: PackedVector3Array, _color_len: float = 0, _moved: float = 0) -> void:
	assert(false, "Needs to be implemented by subclass or only used as interface type")
