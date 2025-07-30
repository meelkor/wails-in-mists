## Node which marks a position and what kind of NPC should be spawned. While
## this node takes care of creating the NPC controller, it doesn't add it to
## the tree - that should be done by the level instead, so all the created NPC
## controllers are then together and easy to manage.
##
## TODO: Not sure whether to use something like the drafted NpcTemplates (and
## only store some variables about the character: alive, position, params with
## which it was generated) or use characters directly and if they are not
## unique store the whole character resource in save. Maybe I'll need to rework
## GameCharacter a little so properties that do not change for NPCs are in
## separate child resource.
## - Wait, none of that can work for unique characters anyway since their
##   position won't get stored anywhere... I really need to split GameCharacter
##   resource, so things like position is in some parent class and things like
##   level attributes etc in child resource that can be unique.
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

## Character to spawn. Takes precedence over NpcTemplate
@export var npc: NpcCharacter

## Whether character should be duplicated and thus used as kinda template. Only
## used when spawning specific NpcCharacter.
@export var as_template: bool


## Create controller according to this spawner's parameters
func create_controller() -> NpcController:
	var character := _get_character()
	character.enable()
	var npc_controller := preload("res://lib/controllers/npc_controller.tscn").instantiate() as NpcController
	character.position = position
	npc_controller.global_transform = global_transform
	npc_controller.character = character
	return npc_controller


func _ready() -> void:
	if Engine.is_editor_hint():
		var mesh := EditorMeshBuilder.make_editor_mesh()
		add_child(mesh)
		mesh.owner = self
		_update_tool_icon()
	if not template and not npc:
		push_warning("There is empty spawner! %s" % name)


func _get_character() -> NpcCharacter:
	var character: NpcCharacter
	if npc:
		character = npc.duplicate() if as_template else npc
	elif template:
		character = template.make_game_character()
		character.enemy = template.default_is_enemy
	else:
		push_warning("%s: Nothing to spawn!" % name)
		character = NpcCharacter.new()
	return character



func _update_tool_icon() -> void:
	var mesh_instance := get_child(0) as MeshInstance3D
	if mesh_instance:
		var mat := mesh_instance.material_override as StandardMaterial3D
		var character := _get_character()
		if character:
			if character.enemy:
				mat.albedo_texture = load("res://resources/class_icons/enemy_spawner.svg")
			else:
				mat.albedo_texture = load("res://resources/class_icons/npc_spawner.svg")
		else:
			mat.albedo_texture = load("res://resources/class_icons/character_spawner.svg")
