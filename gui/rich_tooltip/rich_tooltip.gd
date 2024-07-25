@tool
extends Control

var _shader: ShaderMaterial

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_shader = %TextureRect.material
	_update()


func _notification(what):
	match what:
		NOTIFICATION_RESIZED:
			_update()


func _update():
	if _shader:
		_shader.set_shader_parameter("size", size)
