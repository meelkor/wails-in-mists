@tool
## Script for notification GUI node, which fades in background and provided
## text.
##
## todo: fade out?
extends AspectRatioContainer

const _FADE_IN_SEC = 1.0

@export var title: String

@export var text: String

@onready var _text_label := %TextLabel as Label
@onready var _title_label := %TitleLabel as Label
@onready var _shader_mat := ($Background as TextureRect).material as ShaderMaterial
@onready var _title_cl := _title_label.get_theme_color("font_color")
@onready var _text_cl := _text_label.get_theme_color("font_color")

var _elapsed := 0.


func _ready() -> void:
	_update_style(0.)


func _process(delta: float) -> void:
	if visible:
		_elapsed = clampf(_elapsed + delta / _FADE_IN_SEC, 0.0, 1.0)
		_update_style(sin((_elapsed * PI) / 2))


func _update_style(opacity: float) -> void:
	_title_label.text = title
	_text_label.text = text
	_title_label.add_theme_color_override("font_color", Color(_title_cl, opacity))
	_text_label.add_theme_color_override("font_color", Color(_text_cl, opacity))
	_shader_mat.set_shader_parameter("alpha_scissor", opacity)


func _on_visibility_changed() -> void:
	_elapsed = 0.
