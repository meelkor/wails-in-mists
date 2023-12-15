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
		_display_editor_indicator()
		_update_tool_icon()
	elif template:
		var character = template.make_game_character()
		var packed_chara_controller = preload("res://scenes/character_controller/character_controller.tscn")
		var chara_controller = packed_chara_controller.instantiate()
		chara_controller.setup(character)
		add_child(chara_controller)
	else:
		push_warning("There is empty spawner! %s" % name)

func _display_editor_indicator() -> void:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.position.y += 0.03
	mesh_instance.cast_shadow = false
	var qmesh: QuadMesh = QuadMesh.new()
	qmesh.size = Vector2(0.4, 0.4)
	qmesh.orientation = PlaneMesh.FACE_Y
	mesh_instance.mesh = qmesh
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mesh_instance.material_override = mat
	add_child(mesh_instance)

func _update_tool_icon():
	var mat = get_child(0).material_override
	if template:
		if template.default_is_enemy:
			mat.albedo_texture = load("res://class_icons/enemy_spawner.svg")
		else:
			mat.albedo_texture = load("res://class_icons/npc_spawner.svg")
	else:
		mat.albedo_texture = load("res://class_icons/character_spawner.svg")

