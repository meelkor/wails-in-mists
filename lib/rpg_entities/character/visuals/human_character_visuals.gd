class_name HumanCharacterVisuals
extends CharacterVisuals

## Hair scene that should be instantiated and attached to character's head
@export var hair: PackedScene

## Hair color that multiplies the hair texture (thus usually ends up darker
## that the provided color)
@export var hair_color: Color

## Color used as background for the skin texture. Not all colors may play well
## with the default face texture.
@export var skin_color: Color

var _equipment_models: EquipmentModels = EquipmentModels.new()

## Scene created during the make_model scene
var _scene: CharacterScene

var _character_material: ShaderMaterial

var _base_skin: Image


## Load human model, attach hair and update skin texture. Original model's
## texture is ignored.
func make_scene(character: GameCharacter, in_combat: bool) -> CharacterScene:
	if not _scene:
		_scene = preload("res://models/human_female.tscn").instantiate() as CharacterScene
		_character_material = preload("res://materials/character/character.tres").duplicate() as ShaderMaterial
		_scene.body.material_override = _character_material
		_base_skin = _prepare_base_skin()
		if hair:
			_scene.skeleton.add_child(_build_hair())

	for node in _equipment_models.get_all_nodes():
		node.get_parent().remove_child(node)
		node.queue_free()

	_equipment_models = _build_equipment_models(character)

	for node in _equipment_models.get_all_nodes():
		node.owner = null
		if node.get_parent():
			node.reparent(_scene.skeleton, false)
		else:
			_scene.skeleton.add_child(node)
		node.owner = _scene.skeleton
	_update_equipment_attachments(in_combat)

	_character_material.set_shader_parameter("texture_albedo", _make_skin_texture(character))

	return _scene


## Create hair bone attachment for this character visuals
func _build_hair() -> BoneAttachment3D:
	# todo: hair should get its own material ig
	var hair_mesh_instance := hair.instantiate() as MeshInstance3D
	var hair_attachment := BoneAttachment3D.new()
	hair_attachment.bone_name = AttachableBone.HEAD
	if hair_mesh_instance:
		hair_attachment.add_child(hair_mesh_instance)
		var orig_material := hair_mesh_instance.mesh.surface_get_material(0) as StandardMaterial3D
		var sample_material := preload("res://materials/character/character.tres")
		# todo: use instance uniforms so we do not need to duplicate it?
		var material := sample_material.duplicate() as ShaderMaterial
		material.set_shader_parameter("albedo", hair_color)
		material.set_shader_parameter("albedo_mix", 1.0)
		if orig_material and orig_material.albedo_texture:
			material.set_shader_parameter("texture_albedo", orig_material.albedo_texture)
		hair_mesh_instance.material_override = material
	else:
		push_warning("Referenced hair {} is not MeshInstance3D %s" % hair)
	return hair_attachment


## Build texture which should be used as skin. Every piece of equipment may
## draw whatever it needs into this texture
func _prepare_base_skin() -> Image:
	# Image which is then used as the final skin texture.
	var base_skin := Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
	base_skin.fill(skin_color)
	var char_decorations := preload("res://resources/textures/skin_decorations.png")
	base_skin.blend_rect(char_decorations, Rect2i(0, 0, 1024, 1024), Vector2i.ZERO)
	return base_skin


func _make_skin_texture(character: GameCharacter) -> ImageTexture:
	var char_tex_img := _base_skin.duplicate() as Image
	for slot: ItemEquipment.Slot in ItemEquipment.Slot.values():
		var slotted_item_ref := character.equipment.get_entity(slot)
		if slotted_item_ref:
			var slotted_item := slotted_item_ref.item as ItemEquipment
			if slotted_item && slotted_item.character_texture:
				char_tex_img.blend_rect(slotted_item.character_texture, Rect2i(0, 0, 1024, 1024), Vector2i.ZERO)

	return ImageTexture.create_from_image(char_tex_img)


## According to character's state, preapre bone attachments and rigged models,
## which should be added to character's skeleton. Each such returned node
## should be alse reparented and set owner to that skeleton.
func _build_equipment_models(character: GameCharacter) -> EquipmentModels:
	var out := EquipmentModels.new()
	for slot: ItemEquipment.Slot in ItemEquipment.Slot.values():
		var slotted_item_ref := character.equipment.get_entity(slot)
		if slotted_item_ref:
			var slotted_item := slotted_item_ref.item as ItemEquipment
			if slotted_item && slotted_item.model:
				var model_scn := slotted_item.model.instantiate() as Node3D
				var mesh_instances := model_scn.find_children("", "MeshInstance3D")
				for inst: MeshInstance3D in mesh_instances:
					inst.material_overlay = preload("res://materials/mask/character_depth_mask.tres")
				if slotted_item.free_bone:
					var attachment := BoneAttachment3D.new()
					attachment.add_child(model_scn)
					out.attachments[slotted_item] = attachment
				else:
					out.rigged.append_array(mesh_instances)
	return out


## Update equipment's attachment's bones based on whether combat is active
func _update_equipment_attachments(in_combat: bool) -> void:
	for item in _equipment_models.attachments:
		var att := _equipment_models.attachments[item]
		att.bone_name = item.combat_bone if in_combat else item.free_bone
		var model := att.get_child(0) as Node3D
		# todo: how to properly store the offsets? per bone? per item? should
		# the info about bones and offsets be in some separate resource so many
		# weapons may share the same configuration? <- yes
		if att.bone_name == AttachableBone.PELVIS_L:
			model.position = Vector3(-0.091, 0.234, 0.082)
			# todo: find a nice way to copy rotation from godot editor so I
			# don't need to type and convert manually
			model.rotation = Vector3(deg_to_rad(11.3), deg_to_rad(121.0), deg_to_rad(142.3))
		if att.bone_name == AttachableBone.HAND_R:
			model.position = Vector3(0, 0.1, 0.05)
			model.rotation = Vector3(-PI / 2., 0, 0)


class EquipmentModels:
	extends RefCounted

	var attachments: Dictionary[ItemEquipment, BoneAttachment3D] = {}

	var rigged: Array[MeshInstance3D] = []


	func get_all_nodes() -> Array[Node3D]:
		var nodes: Array[Node3D] = []
		nodes.append_array(rigged)
		nodes.append_array(attachments.values())
		return nodes
