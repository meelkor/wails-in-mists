## Utility class for creating character's mesh instance according to given
## GameCharacter

class_name CharacterMeshBuilder
extends Object

## Create hair bone attachment for given character
static func build_hair(character: GameCharacter, hair_material: ShaderMaterial = preload("res://materials/character/character.tres")) -> BoneAttachment3D:
	var hair_mesh_instance := character.hair.instantiate() as MeshInstance3D
	var hair_attachment := BoneAttachment3D.new()
	hair_attachment.bone_name = AttachableBone.HEAD
	hair_attachment.add_child(hair_mesh_instance)
	if hair_mesh_instance:
		var orig_material := hair_mesh_instance.mesh.surface_get_material(0) as StandardMaterial3D
		var hair_mat := hair_material.duplicate() as ShaderMaterial
		hair_mat.set_shader_parameter("albedo", character.hair_color)
		hair_mat.set_shader_parameter("albedo_mix", 1.0)
		if orig_material and orig_material.albedo_texture:
			hair_mat.set_shader_parameter("texture_albedo", orig_material.albedo_texture)
		hair_mesh_instance.material_override = hair_mat
	else:
		push_warning("Referenced hair {} is not MeshInstance3D %s" % character.hair)
	return hair_attachment


## Build texture which should be used as skin. Every piece of equipment may
## draw whatever it needs into this texture
static func build_character_texture(character: GameCharacter) -> ImageTexture:
	# Image which is then used as the final skin texture.
	var char_tex_img := Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
	char_tex_img.fill(character.skin_color)
	var char_decorations := preload("res://resources/textures/skin_decorations.png")
	char_tex_img.blend_rect(char_decorations, Rect2i(0, 0, 1024, 1024), Vector2i.ZERO)

	for slot: ItemEquipment.Slot in ItemEquipment.Slot.values():
		var slotted_item_ref := character.equipment.get_entity(slot)
		if slotted_item_ref:
			var slotted_item := slotted_item_ref.item as ItemEquipment
			if slotted_item && slotted_item.character_texture:
				char_tex_img.blend_rect(slotted_item.character_texture, Rect2i(0, 0, 1024, 1024), Vector2i.ZERO)

	return ImageTexture.create_from_image(char_tex_img)


## Load scene for given character should contain character mesh and its
## animation player. Character texture is ignored as it's always overriden.
static func load_human_model(character: GameCharacter, chara_material: ShaderMaterial = preload("res://materials/character/character.tres")) -> CharacterScene:
	var char_scene := character.model.instantiate() as CharacterScene
	var char_material := chara_material.duplicate() as ShaderMaterial
	char_scene.body.material_override = char_material
	return char_scene


## According to character's state, preapre bone attachments and rigged models,
## which should be added to character's skeleton. Each such returned node
## should be alse reparented and set owner to that skeleton.
static func build_equipment_models(character: GameCharacter) -> EquipmentModels:
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


## Helper which finds the first mesh instance in given scene. Character scenes
## are expected to always have exactly one mesh instance.
static func find_mesh_instance(char_scn: Node3D) -> MeshInstance3D:
	return char_scn.find_children("", "MeshInstance3D")[0]


class EquipmentModels:
	extends RefCounted

	var attachments: Dictionary[ItemEquipment, BoneAttachment3D] = {}

	var rigged: Array[MeshInstance3D] = []


	func get_all_nodes() -> Array[Node3D]:
		var nodes: Array[Node3D] = []
		nodes.append_array(rigged)
		nodes.append_array(attachments.values())
		return nodes
