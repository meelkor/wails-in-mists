extends TextureRect
class_name FramedDialog

var grayscale: float:
	set(v):
		(material as ShaderMaterial).set_shader_parameter("grayscale", v)


func _ready() -> void:
	# Until canvas_item shader start supporting instanced uniforms as promised
	# in https://godotengine.org/article/godot-40-gets-global-and-instance-shader-uniforms/
	material = preload("res://materials/canvas/ui_dialog_material.tres").duplicate()

func _process(_delta: float) -> void:
	# TODO: listen to some "resize" event if it exists
	(material as ShaderMaterial).set_shader_parameter("size", size)
