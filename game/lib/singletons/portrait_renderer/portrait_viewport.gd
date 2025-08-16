## Node which renders given character's model in separate viewport with some
## dumb postprocessing to create texture to be used as that character's
## portrait.
##
## For each rendered portrait a new viewport needs to be created so we can
## render multiple portraits on single frame.
extends SubViewport

const portrait_material = preload("res://materials/character/portrait_character.tres") as ShaderMaterial


## todo: try using compute shaders for this, so it doesn't
##
## todo: use different background depending on character "type"?
func render(character: GameCharacter) -> Texture:
	var visuals := character.visuals.duplicate() as CharacterVisuals
	var character_scene := visuals.make_scene(character, false) if character.visuals else null

	if not character_scene:
		character_scene = preload("res://models/characters/placeholder_character.tscn").instantiate()
		push_warning("Character %s has invalid visuals" % character)

	var min_z: float = 100.
	var height: float = -1

	for mesh: MeshInstance3D in character_scene.find_children("", "MeshInstance3D"):
		if mesh.material_overlay:
			mesh.material_overlay = null
		var aabb := mesh.get_aabb()
		min_z = min(aabb.position.z, min_z)
		height = max(aabb.end.y, height)

	for particles: GPUParticles3D in character_scene.find_children("", "GPUParticles3D"):
		particles.request_particles_process(10.8)

	var camera := ($Content/Camera3D as Camera3D)
	if character_scene.portrait_camera:
		# model-specific camera
		character_scene.portrait_camera.current = true
	else:
		# default camera
		camera.current = true
		camera.global_position.z = min_z - 0.25
		camera.global_position.y = height - 0.03

	add_child(character_scene)
	render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	# We need to render it twice for gpu particles to work
	render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	return ImageTexture.create_from_image(get_texture().get_image())
