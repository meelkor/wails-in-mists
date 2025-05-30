@tool
extends PanelContainer
class_name FramedDialog

@export var texture: Texture2D

@export_range(0, 1, 0.1)
var grayscale: float = 0:
	set(v):
		grayscale = v
		_update_uniforms()

@export_range(0, 1, 0.01)
var bg_opacity: float = 1.0:
	set(v):
		bg_opacity = v
		_update_uniforms()

@export var border_tint: Color = Color.TRANSPARENT:
	set(v):
		border_tint = v
		_update_uniforms()

@export var resizable_top: bool = false;

var _resizing: bool = false

signal resize_top(top_offset: float)

func _ready() -> void:
	# Until canvas_item shader start supporting instanced uniforms as promised
	# in https://godotengine.org/article/godot-40-gets-global-and-instance-shader-uniforms/
	material = preload("res://materials/canvas/ui_dialog_material.tres").duplicate()
	_update_uniforms()

func _process(_delta: float) -> void:
	# TODO: listen to some "resize" event if it exists
	(material as ShaderMaterial).set_shader_parameter("size", size)

func _update_uniforms() -> void:
	(material as ShaderMaterial).set_shader_parameter("grayscale", grayscale)
	(material as ShaderMaterial).set_shader_parameter("bg_opacity", bg_opacity)
	(material as ShaderMaterial).set_shader_parameter("border_tint", border_tint)
	(material as ShaderMaterial).set_shader_parameter("bg_texture", texture)

func _gui_input(event: InputEvent) -> void:
	if resizable_top:
		var motion := event as InputEventMouseMotion
		if motion:
			var on_top_border: bool = motion.position.y < 8
			var pressed: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

			if on_top_border || _resizing:
				mouse_default_cursor_shape = CursorShape.CURSOR_VSIZE
				if pressed:
					_resizing = true
					resize_top.emit(-motion.position.y)
				else:
					_resizing = false
			else:
				_resizing = false
				mouse_default_cursor_shape = CursorShape.CURSOR_ARROW
