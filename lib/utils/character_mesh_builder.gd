## Utility class for creating character's mesh instance according to given
## GameCharacter

class_name CharacterMeshBuilder
extends Object

## Create hair bone attachment for given character
static func build_hair(character: GameCharacter) -> BoneAttachment3D:
	var hair_mesh_instance := character.hair.instantiate() as MeshInstance3D
	var hair_attachment := BoneAttachment3D.new()
	hair_attachment.bone_name = AttachableBone.HEAD
	hair_attachment.add_child(hair_mesh_instance)
	if hair_mesh_instance is MeshInstance3D:
		var hair_mat := preload("res://materials/character/character.tres").duplicate(true) as ShaderMaterial
		hair_mat.set_shader_parameter("albedo", character.hair_color)
		hair_mat.set_shader_parameter("albedo_mix", 1.0)
		hair_mesh_instance.material_override = hair_mat
	else:
		push_warning("Referenced hair {} is not MeshInstance3D %s" % character.hair)
	return hair_attachment


## Build texture which should be used as skin. Every piece of equipment may
## draw whatever it needs into this texture
static func build_character_texture(character: GameCharacter) -> ImageTexture:
	# Image which is then used as the final skin texture.
	var char_tex_img := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	char_tex_img.fill(character.skin_color)

	for slot: ItemEquipment.Slot in ItemEquipment.Slot.values():
		var slotted_item_ref := character.equipment.get_entity(slot)
		if slotted_item_ref:
			var slotted_item := slotted_item_ref.item as ItemEquipment
			if slotted_item && slotted_item.character_texture:
				var sub_img := load(slotted_item.character_texture) as Image
				char_tex_img.blend_rect(sub_img, Rect2i(0, 0, 512, 512), Vector2i.ZERO)

	return ImageTexture.create_from_image(char_tex_img)


## Load scene for given character should contain character mesh and its
## animation player. Character texture is ignored as it's always overriden.
static func load_human_model(character: GameCharacter) -> Node3D:
	var char_model := character.model.instantiate() as Node3D
	char_model.name = "CharacterModel"

	var char_material := preload("res://materials/character/character.tres").duplicate() as ShaderMaterial
	find_mesh_instance(char_model).set_surface_override_material(0, char_material)
	return char_model


## According to character's state, preapre bone attachments and rigged models,
## which should be added to character's skeleton. Each such returned node
## should be alse reparented and set owner to that skeleton.
static func build_equipment_models(character: GameCharacter) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for slot: ItemEquipment.Slot in ItemEquipment.Slot.values():
		var slotted_item_ref := character.equipment.get_entity(slot)
		if slotted_item_ref:
			var slotted_item := slotted_item_ref.item as ItemEquipment
			if slotted_item && slotted_item.model:
				var model_scn := slotted_item.model.instantiate()
				if slotted_item.model_bone:
					var attachment := BoneAttachment3D.new()
					attachment.bone_name = slotted_item.model_bone
					attachment.add_child(model_scn)
					out.append(attachment)
				else:
					var eq_meshes := model_scn.find_children("", "MeshInstance3D")
					out.append_array(eq_meshes)
	return out


## Helper which finds the first mesh instance in given scene. Character scenes
## are expected to always have exactly one mesh instance.
static func find_mesh_instance(char_scn: Node3D) -> MeshInstance3D:
	return char_scn.find_children("", "MeshInstance3D")[0]
