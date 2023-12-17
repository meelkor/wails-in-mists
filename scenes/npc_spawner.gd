# Node which marks a position and what kind of NPC should be spawned. While
# this node takes care of creating the NPC controller, it doesn't add it to the
# tree - that should be done by the level instead, so all the created NPC
# controllers are then together and easy to manage.
#
# TODO: Come up with solution for conditional spawning

@tool
@icon("res://resources/class_icons/character_spawner.svg")
class_name NpcSpawner
extends Node3D

@export var template: NpcTemplate:
	set(v):
		template = v
		if Engine.is_editor_hint():
			_update_tool_icon()

# Create controller according to this spawner's parameters
func create_controller() -> NpcController:
	var character = template.make_game_character()
	character.position = global_position
	var packed_npc_controller = preload("res://lib/controllers/npc_controller.tscn")
	var npc_controller = packed_npc_controller.instantiate()
	npc_controller.character = character
	return npc_controller

func _ready() -> void:
	if Engine.is_editor_hint():
		var mesh = EditorMeshBuilder.make_editor_mesh()
		add_child(mesh)
		mesh.owner = self
		_update_tool_icon()
	if not template:
		push_warning("There is empty spawner! %s" % name)

func _update_tool_icon():
	var mat = get_child(0).material_override
	if template:
		if template.default_is_enemy:
			mat.albedo_texture = load("res://resources/class_icons/enemy_spawner.svg")
		else:
			mat.albedo_texture = load("res://resources/class_icons/npc_spawner.svg")
	else:
		mat.albedo_texture = load("res://resources/class_icons/character_spawner.svg")
