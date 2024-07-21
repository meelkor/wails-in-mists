## Node that makes child mesh interactable, opening looting interface with
## given items
class_name Lootable
extends Node3D

@export var items: Array[Item] = []

func _ready() -> void:
	var meshes = find_children("", "MeshInstance3D")
	for mesh in meshes:
		mesh.add_to_group("interactable")

func _input_event(_camera, e, _position, _normal, _shape_idx):
	print(e)
