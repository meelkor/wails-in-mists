## Node which renders given character's model in separate viewport with some
## dumb postprocessing to create texture to be used as that character's
## portrait.
##
## For each rendered portrait a new viewport needs to be created so we can
## render multiple portraits on single frame.
extends SubViewport

const portrait_material = preload("res://materials/character/portrait_character.tres") as ShaderMaterial


## todo: camera position is currently hard-position to aim at human head.
## Consider adding "portrait camera" to each model scene, so this script can
## then just take it and doesn't need to know where and how large the model is.
##
## todo: try using compute shaders for this, so it doesn't
##
## todo: use different background depending on character "type"?
func render(character: GameCharacter) -> Texture:
	# todo: shared code with CharacterController, move somewhere else
	var character_scene := CharacterMeshBuilder.load_human_model(character, portrait_material)
	if character.hair:
		character_scene.skeleton.add_child(CharacterMeshBuilder.build_hair(character, portrait_material))
	var char_tex := CharacterMeshBuilder.build_character_texture(character)
	# todo: this is all very ugly, but as long as I don't know how it's gonna
	# work for the rest of the models it's not really worth refactoring and
	# creating some abstraction.
	(character_scene.body.material_override as ShaderMaterial).set_shader_parameter("texture_albedo", char_tex)
	render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(character_scene)
	await RenderingServer.frame_post_draw
	return get_texture()
