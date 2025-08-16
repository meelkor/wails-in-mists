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
	var visuals := character.visuals.duplicate() as CharacterVisuals
	var character_scene := visuals.make_scene(character, false) if character.visuals else null

	if not character_scene:
		character_scene = preload("res://models/characters/placeholder_character.tscn").instantiate()
		push_warning("Character %s has invalid visuals" % character)

	for mesh: MeshInstance3D in character_scene.find_children("", "MeshInstance3D"):
		# todo: very human character specific, may break others, should be
		# handled by the scene, as it is now the mesh material must not be
		# transparent/read from screen. Will be fixed by proper post-effects
		# ig?
		if mesh.material_override:
			var override := mesh.material_override.duplicate() as Material
			override.next_pass = null
			mesh.material_override = override

	# todo: this is all very ugly, but as long as I don't know how it's gonna
	# work for the rest of the models it's not really worth refactoring and
	# creating some abstraction.
	render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(character_scene)
	await RenderingServer.frame_post_draw
	return get_texture()
