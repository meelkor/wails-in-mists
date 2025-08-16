## Single texture in the AtlasMaterial's atlas
@tool
class_name AtlasImage
extends Resource

@export var albedo: Image:
	set(v):
		albedo = v
		emit_changed()

@export var normal: Image:
	set(v):
		normal = v
		emit_changed()
