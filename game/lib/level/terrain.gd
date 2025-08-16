## Abstract class with unified interface to work with the terrain, no matter
## how the terrain is actually rendered (static terrain vs. terrain3d since I
## am still not sure which I am gonna use in the end...)
@abstract
class_name Terrain
extends Node

signal input_event(e: InputEvent, world_position: Vector3)


func snap_down(_pos: Vector3) -> Vector3:
	assert(false, "Needs to be implemented by subclass or only used as interface type")
	return Vector3.ZERO
