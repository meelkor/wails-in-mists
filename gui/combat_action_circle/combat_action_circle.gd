@tool
extends TextureRect

@export var attribute: CharacterAttribute:
	set(v):
		attribute = v
		_ready()

@export_range(0, 1, 0.01) var used: float = 0.0:
	set(v):
		used = v
		_ready()

@export var preview: bool = false:
	set(v):
		preview = v
		_ready()


func _init() -> void:
	material = material.duplicate()


func _ready() -> void:
	var sm := material as ShaderMaterial
	if attribute:
		sm.set_shader_parameter("offset", attribute.atlas_position + 1)
	else:
		sm.set_shader_parameter("offset", 1)
	sm.set_shader_parameter("used_ratio", used)
	sm.set_shader_parameter("saturation", 0.25 if preview else 1.0)
