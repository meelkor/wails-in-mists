@tool
@icon("res://resources/class_icons/player_spawner.svg")
class_name PlayerSpawn
extends Node3D


func _ready() -> void:
	if Engine.is_editor_hint():
		var mesh := EditorMeshBuilder.make_editor_mesh("res://resources/class_icons/player_spawner.svg")
		add_child(mesh)
		mesh.owner = self
