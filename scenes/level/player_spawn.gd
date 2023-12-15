@tool
@icon("res://class_icons/player_spawner.svg")
class_name PlayerSpawn
extends Node3D

func _ready() -> void:
	if Engine.is_editor_hint():
		add_child(EditorMeshBuilder.make_editor_mesh("res://class_icons/player_spawner.svg"))
