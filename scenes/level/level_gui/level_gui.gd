class_name LevelGui
extends Control

const frame_image_default = preload("res://textures_ui/level_character_frame_unaccented.png")
const frame_image_selected = preload("res://textures_ui/level_character_frame_selected.png")

var _portraits: Dictionary = {}

# Create portraits for given characters and listen for their state change
func set_characters(characters: Array[PlayableCharacter]):
	for character in characters:
		_register_character(character)

# Prepare button for the character's portrait and store ref to the character
func _register_character(character: PlayableCharacter):
	var button = TextureButton.new()
	button.mouse_filter = Control.MOUSE_FILTER_STOP

	_update_portrait_button(character, button)
	_portraits[character.get_instance_id()] = {
		"character": character,
		"button": button,
	}
	$CharactersColumn.add_child(button)

	button.pressed.connect(_on_portrait_button_click.bind(character))
	character.selected_changed.connect(_on_character_selected_changed, Object.ConnectFlags.CONNECT_DEFERRED)

# Re-create texture for existing rect based on given character's state
func _update_portrait_button(character: PlayableCharacter, button: TextureButton):
	var portrait_image = load(character.portrait) as Image
	var frame_image = frame_image_selected if character.selected else frame_image_default
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
	button.texture_normal = tex

# Character event handler
func _on_character_selected_changed(character: PlayableCharacter, _s):
	var existing_char_dict = _portraits.get(character.get_instance_id())
	_update_portrait_button(character, existing_char_dict.button)

# Child button event handler
func _on_portrait_button_click(character: PlayableCharacter):
	if Input.is_key_pressed(KEY_SHIFT):
		character.selected = true
	else:
		# TODO: I probably want to use singleton for this deselect others and
		# select this shit...
		var selected_characters_node = get_node("/root/GameRoot/Level/ControlledCharacters") as ControlledCharacters
		selected_characters_node.select_single(character)
