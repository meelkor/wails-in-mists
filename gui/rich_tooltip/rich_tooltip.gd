@tool
extends Control

var _shader: ShaderMaterial

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_shader = (%TextureRect as TextureRect).material
	_update()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			_update()


func _update() -> void:
	if _shader:
		_shader.set_shader_parameter("size", size)
