class_name CharacterPortrait
extends BoxContainer

const frame_default_stylebox = preload("./frame_default_stylebox.tres")
const frame_selected_stylebox = preload("./frame_selected_stylebox.tres")

var di := DI.new(self)

@export var character: PlayableCharacter

@onready var _frame_container := %FrameContainer as PanelContainer
@onready var _portrait_container := %PortraitContainer as PanelContainer

var _portrait_stylebox := StyleBoxTexture.new()


func _ready() -> void:
	mouse_entered.connect(func () -> void: character.hovered = true)
	mouse_exited.connect(func () -> void: character.hovered = false)
	_portrait_container.add_theme_stylebox_override("panel", _portrait_stylebox)
	_update_texture()
	character.changed.connect(_update_texture)


## Announce that dialog is open for given character and update portrait state
func announce_dialog_open(chara_or_null: GameCharacter) -> void:
	var opacity := 1.0 if chara_or_null == character || chara_or_null == null else 0.42
	_portrait_stylebox.modulate_color = Color(opacity, opacity, opacity)


## Re-create texture for existing rect based on given character's state
func _update_texture() -> void:
	_portrait_stylebox.texture = character.get_portrait_texture()
	if character.selected:
		_frame_container.add_theme_stylebox_override("panel", frame_selected_stylebox)
	else:
		_frame_container.add_theme_stylebox_override("panel", frame_default_stylebox)


## Portrait node click handler
func _gui_input(e: InputEvent) -> void:
	var btn_event := e as InputEventMouseButton
	if btn_event and btn_event.pressed:
		if btn_event.button_index == MOUSE_BUTTON_RIGHT:
			character.clicked.emit(GameCharacter.InteractionType.INSPECT)
		elif btn_event.button_index == MOUSE_BUTTON_LEFT:
			if Input.is_key_pressed(KEY_SHIFT):
				character.clicked.emit(GameCharacter.InteractionType.SELECT_MULTI)
			else:
				character.clicked.emit(GameCharacter.InteractionType.SELECT)
