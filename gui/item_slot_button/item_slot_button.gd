## Button which may hold single item, displaying its icon and opening its
## tooltip on hover. For use inside inventory, containers etc.
##
## todo: very similar to ability bar button, how to consolidate those two?
extends Control

@export var text: String = ""

@export var icon: Texture2D:
	set (v):
		icon = v
		_update()

var _shader: ShaderMaterial

var _dummy_icon: Texture2D

var _hovered = false

func _ready() -> void:
	# todo: use instance variables once supported by canvas shaders so we do
	# not need to duplicate it for every slot.
	_shader = $ColorRect.material.duplicate()
	$ColorRect.material = _shader
	_dummy_icon = _shader.get_shader_parameter("icon_tex")
	_shader.set_shader_parameter("noise_offset", randf())
	_update()

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _update() -> void:
	_shader.set_shader_parameter("size", size)
	_shader.set_shader_parameter("hover_weight", 1.0 if _hovered and icon else 0.0)
	if icon:
		_shader.set_shader_parameter("icon_tex", icon)
		_shader.set_shader_parameter("has_icon", true)
	else:
		_shader.set_shader_parameter("icon_tex", _dummy_icon)
		_shader.set_shader_parameter("has_icon", false)


func _on_mouse_entered() -> void:
	_hovered = true
	_update()


func _on_mouse_exited() -> void:
	_hovered = false
	_update()
