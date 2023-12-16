# Node which creates character controller on its position on level
# initialization.
#
# TODO: Come up with solution for conditional spawning

@tool
@icon("res://class_icons/character_spawner.svg")
class_name NpcSpawner
extends Node3D

@export var template: NpcTemplate:
	set(v):
		template = v
		if Engine.is_editor_hint():
			_update_tool_icon()

func _ready() -> void:
	if Engine.is_editor_hint():
		var mesh = EditorMeshBuilder.make_editor_mesh()
		add_child(mesh)
		mesh.owner = self
		_update_tool_icon()
	elif template:
		var character = template.make_game_character()
		var packed_npc_controller = preload("res://logic/controllers/npc_controller.tscn")
		var npc_controller = packed_npc_controller.instantiate()
		npc_controller.setup(character)
		add_child(npc_controller)
	else:
		push_warning("There is empty spawner! %s" % name)

func _update_tool_icon():
	var mat = get_child(0).material_override
	if template:
		if template.default_is_enemy:
			mat.albedo_texture = load("res://class_icons/enemy_spawner.svg")
		else:
			mat.albedo_texture = load("res://class_icons/npc_spawner.svg")
	else:
		mat.albedo_texture = load("res://class_icons/character_spawner.svg")
