## Node which marks a position and what kind of NPC should be spawned. While
## this node takes care of creating the NPC controller, it doesn't add it to the
## tree - that should be done by the level instead, so all the created NPC
## controllers are then together and easy to manage.
##
## TODO: Come up with solution for conditional spawning
@tool
@icon("res://resources/class_icons/character_spawner.svg")
class_name NpcSpawner
extends Node3D

@export var template: NpcTemplate:
	set(v):
		template = v
		if Engine.is_editor_hint() and get_child_count() > 0:
			_update_tool_icon()


## Create controller according to this spawner's parameters
func create_controller() -> NpcController:
	var character := template.make_game_character()
	character.position = global_position
	var npc_controller := preload("res://lib/controllers/npc_controller.tscn").instantiate() as NpcController
	npc_controller.character = character
	return npc_controller


func _ready() -> void:
	if Engine.is_editor_hint():
		var mesh := EditorMeshBuilder.make_editor_mesh()
		add_child(mesh)
		mesh.owner = self
		_update_tool_icon()
	if not template:
		push_warning("There is empty spawner! %s" % name)


func _update_tool_icon() -> void:
	var mesh_instance := get_child(0) as MeshInstance3D
	if mesh_instance:
		var mat := mesh_instance.material_override as StandardMaterial3D
		if template:
			if template.default_is_enemy:
				mat.albedo_texture = load("res://resources/class_icons/enemy_spawner.svg")
			else:
				mat.albedo_texture = load("res://resources/class_icons/npc_spawner.svg")
		else:
			mat.albedo_texture = load("res://resources/class_icons/character_spawner.svg")
