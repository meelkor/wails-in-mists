extends BoxContainer
class_name CharacterPortrait

const frame_image_default = preload("res://textures_ui/level_character_frame_unaccented.png")
const frame_image_selected = preload("res://textures_ui/level_character_frame_selected.png")

signal right_click(character: PlayableCharacter)

var _character: PlayableCharacter

# Setup node's state, should be called before adding to tree
func setup(character: PlayableCharacter):
	_character = character
	character.selected_changed.connect(_update_texture, Object.ConnectFlags.CONNECT_DEFERRED)
	_update_texture(character, character.selected)

# Announce that dialog is open for given character and update portrait state
func announce_dialog_open(characterOrNull):
	var opacity = 0.0 if characterOrNull == _character || characterOrNull == null else 0.58
	($PortraitButton.material as ShaderMaterial).set_shader_parameter("overlay_opacity", opacity)

# Re-create texture for existing rect based on given character's state
func _update_texture(character: PlayableCharacter, selected: bool):
	var portrait_image = load(character.portrait) as Image
	var frame_image = frame_image_selected if selected else frame_image_default
	var frame_size = frame_image.get_size()
	var final_image = Image.create(frame_size.x, frame_size.y, false, Image.FORMAT_RGBA8)
	final_image.blit_rect(
		portrait_image,
		Rect2i(Vector2i.ZERO, portrait_image.get_size()),
		Vector2i(7, 7),
	)
	final_image.blend_rect(
		frame_image,
		Rect2i(Vector2i.ZERO, frame_size),
		Vector2i.ZERO,
	)

	var tex = ImageTexture.create_from_image(final_image)
	$PortraitButton.texture = tex

# Portrait node click handler
func _gui_input(e):
	if e is InputEventMouseButton:
		if e.pressed:
			if Input.is_key_pressed(KEY_SHIFT):
				_character.selected = true
			elif e.button_index == MOUSE_BUTTON_RIGHT:
				right_click.emit(_character)
			elif e.button_index == MOUSE_BUTTON_LEFT:
				global.controlled_characters().select_single(_character)
