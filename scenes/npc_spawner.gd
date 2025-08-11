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
		if Engine.is_editor_hint():
			template.changed.connect(_tool_update_icon)
			_tool_update_icon()

## Character to spawn. Takes precedence over NpcTemplate
@export var npc: NpcCharacter:
	set(v):
		npc = v
		if Engine.is_editor_hint():
			_tool_update_icon()

## Whether character should be duplicated and thus used as kinda template. Only
## used when spawning specific NpcCharacter.
@export var as_template: bool

@export_tool_button("Make template", "RetargetModifier3D") var make_template_btn := func () -> void:
	EditorInterface.popup_quick_open(_tool_on_make_template_selected, ["CharacterIdentity"])


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
		_tool_update_icon()
		visibility_changed.connect(_tool_update_icon)
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

var _gizmo: Node

## This should probably be a gizmo plugin instead
func _tool_update_icon() -> void:
	var gizmo: Node3D

	if visible:
		if template and template.visuals:
			var visuals := template.visuals.duplicate() as CharacterVisuals
			var tmp_char := GameCharacter.new()
			tmp_char.parameters = template.parameters if template.parameters else CharacterParameters.new()
			tmp_char.identity = template.identity if template.identity else CharacterIdentity.new()
			gizmo = visuals.make_scene(tmp_char, false)
		elif npc and npc.visuals:
			var visuals := npc.visuals.duplicate() as CharacterVisuals
			gizmo = visuals.make_scene(npc, false)
		else:
			var mesh := EditorMeshBuilder.make_editor_mesh()
			var mat := mesh.material_override as StandardMaterial3D
			var character := _get_character()
			if character:
				if character.enemy:
					mat.albedo_texture = load("res://resources/class_icons/enemy_spawner.svg")
				else:
					mat.albedo_texture = load("res://resources/class_icons/npc_spawner.svg")
			else:
				mat.albedo_texture = load("res://resources/class_icons/character_spawner.svg")
			gizmo = mesh

		if gizmo != _gizmo:
			if _gizmo:
				remove_child(_gizmo)
				_gizmo.queue_free()
			var char_scene := gizmo as CharacterScene
			if char_scene:
				char_scene.animation_tree.active = false
			add_child(gizmo)
			gizmo.owner = self
			_gizmo = gizmo


func _tool_on_make_template_selected(selected: StringName) -> void:
	var new_template := NpcTemplate.new()
	new_template.identity = load(selected)
	var params_path := selected.replace("identity", "parameters")
	if ResourceLoader.exists(params_path):
		new_template.parameters = load(params_path)
	var visuals_path := selected.replace("identity", "visuals")
	if ResourceLoader.exists(visuals_path):
		new_template.parameters = load(visuals_path)
	else:
		var scn_path := selected.replace("_identity.tres", ".tscn")
		if ResourceLoader.exists(scn_path):
			var visuals := CustomCharacterVisuals.new()
			visuals.custom_model = load(scn_path)
			visuals.emit_changed()
			new_template.visuals = visuals
	new_template.default_is_enemy = true
	new_template.emit_changed()
	template = new_template
	notify_property_list_changed()
	EditorInterface.mark_scene_as_unsaved()
	_tool_update_icon()
