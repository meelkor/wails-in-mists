extends TextureRect
class_name FramedDialog

@export_range(0, 1, 0.1)
var grayscale: float:
	set(v):
		grayscale = v
		(material as ShaderMaterial).set_shader_parameter("grayscale", v)

@export_range(0, 1, 0.01)
var bg_opacity: float = 1.0:
	set(v):
		bg_opacity = v
		(material as ShaderMaterial).set_shader_parameter("bg_opacity", v)

@export var resizable_top: bool = false;

var _resizing: bool = false

signal resize_top(top_offset: float)

func _ready() -> void:
	# Until canvas_item shader start supporting instanced uniforms as promised
	# in https://godotengine.org/article/godot-40-gets-global-and-instance-shader-uniforms/
	material = preload("res://materials/canvas/ui_dialog_material.tres").duplicate()

func _process(_delta: float) -> void:
	# TODO: listen to some "resize" event if it exists
	(material as ShaderMaterial).set_shader_parameter("size", size)

func _gui_input(event: InputEvent) -> void:
	if resizable_top:
		if event is InputEventMouseMotion:
			var on_top_border: bool = event.position.y < 8
			var pressed: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

			if on_top_border || _resizing:
				mouse_default_cursor_shape = CursorShape.CURSOR_VSIZE
				if pressed:
					_resizing = true
					resize_top.emit(-event.position.y)
				else:
					_resizing = false
			else:
				_resizing = false
				mouse_default_cursor_shape = CursorShape.CURSOR_ARROW
