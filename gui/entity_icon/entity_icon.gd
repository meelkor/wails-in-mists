## Represents "icon" for either ability or item (and possible more in the
## future). Basically just a wrapper around rect with the icon shader.
extends ColorRect

@export var icon: Texture2D:
	set(v):
		icon = v
		_update_tex()

@export var hovered: bool = false:
	set(v):
		hovered = v
		_update_tex()

## Reference to the used shader
var _shader: ShaderMaterial

## Default icon to use when empty
var _dummy_icon: Texture2D


### Lifecycle ###

func _ready() -> void:
	# todo: use instance variables once supported by canvas shaders so we do
	# not need to duplicate it for every slot.
	_shader = material.duplicate()
	material = _shader
	_dummy_icon = _shader.get_shader_parameter("icon_tex")
	_shader.set_shader_parameter("noise_offset", randf())
	_update_tex()


### Private ###

## Update shader with current icon/hovered state
func _update_tex() -> void:
	_shader.set_shader_parameter("size", size)
	_shader.set_shader_parameter("hover_weight", 1.0 if hovered and icon else 0.0)
	if icon:
		_shader.set_shader_parameter("icon_tex", icon)
		_shader.set_shader_parameter("has_icon", true)
	else:
		_shader.set_shader_parameter("icon_tex", _dummy_icon)
		_shader.set_shader_parameter("has_icon", false)
