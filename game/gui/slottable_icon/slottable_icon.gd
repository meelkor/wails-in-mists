## Represents "icon" for any "slottable" entity (ability or item and possible
## more in the future). Basically just a wrapper around rect with the icon
## shader.
class_name SlottableIcon
extends ColorRect

@export var icon: Texture2D:
	set(v):
		if icon != v:
			icon = v
			_needs_update = true

@export var hovered: bool = false:
	set(v):
		if hovered != v:
			hovered = v
			_needs_update = true

@export var dimmed: bool = false:
	set(v):
		if dimmed != v:
			dimmed = v
			_needs_update = true

@export var ghost: bool = false:
	set(v):
		if ghost != v:
			ghost = v
			_needs_update = true

## Reference to the used shader
var _shader: ShaderMaterial

## Default icon to use when empty
var _dummy_icon: Texture2D

var _needs_update := false

### Lifecycle ###

func _ready() -> void:
	# todo: use instance variables once supported by canvas shaders so we do
	# not need to duplicate it for every slot.
	_shader = material.duplicate()
	material = _shader
	_dummy_icon = _shader.get_shader_parameter("icon_tex")
	_update_tex()


func _process(_delta: float) -> void:
	if _needs_update:
		_update_tex()


### Private ###

## Update shader with current icon/hovered state
func _update_tex() -> void:
	_shader.set_shader_parameter("size", size)
	_shader.set_shader_parameter("brightness", 0.4 if dimmed or ghost else 1.0)
	_shader.set_shader_parameter("hover_weight", 1.0 if hovered else 0.0)
	if icon:
		_shader.set_shader_parameter("icon_tex", icon)
		_shader.set_shader_parameter("has_icon", true)
	else:
		_shader.set_shader_parameter("icon_tex", _dummy_icon)
		_shader.set_shader_parameter("has_icon", false)
	_needs_update = false
