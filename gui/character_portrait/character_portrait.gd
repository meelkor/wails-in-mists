class_name CharacterPortrait
extends BoxContainer

const frame_image_default = preload("res://resources/textures/ui/level_character_frame_unaccented.png")
const frame_image_selected = preload("res://resources/textures/ui/level_character_frame_selected.png")

signal clicked(character: PlayableCharacter, type: PlayableCharacter.InteractionType)

@onready var button := $PortraitButton as TextureRect

var _character: PlayableCharacter


func _ready() -> void:
	mouse_entered.connect(func () -> void: _character.hovered = true)
	mouse_exited.connect(func () -> void: _character.hovered = false)
	_update_texture()
	_character.changed.connect(_update_texture)


## Setup node's state, should be called before adding to tree
func setup(character: PlayableCharacter) -> void:
	_character = character


## Announce that dialog is open for given character and update portrait state
func announce_dialog_open(characterOrNull: GameCharacter) -> void:
	var opacity := 0.0 if characterOrNull == _character || characterOrNull == null else 0.58
	(button.material as ShaderMaterial).set_shader_parameter("overlay_opacity", opacity)


## Re-create texture for existing rect based on given character's state
func _update_texture() -> void:
	var portrait_image := load(_character.portrait) as Image
	var frame_image := frame_image_selected if _character.selected else frame_image_default
	var frame_size := frame_image.get_size()
	var final_image := Image.create(frame_size.x, frame_size.y, false, Image.FORMAT_RGBA8)
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

	var tex := ImageTexture.create_from_image(final_image)
	button.texture = tex


## Portrait node click handler
func _gui_input(e: InputEvent) -> void:
	var btn_event := e as InputEventMouseButton
	if btn_event:
		if btn_event.pressed:
			if Input.is_key_pressed(KEY_SHIFT):
				clicked.emit(_character, PlayableCharacter.InteractionType.SELECT_MULTI)
			elif btn_event.button_index == MOUSE_BUTTON_RIGHT:
				clicked.emit(_character, PlayableCharacter.InteractionType.CONTEXT)
			elif btn_event.button_index == MOUSE_BUTTON_LEFT:
				clicked.emit(_character, PlayableCharacter.InteractionType.SELECT_ALONE)
