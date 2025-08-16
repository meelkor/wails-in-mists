## Base class for any kind of resource that can be used with slot containers.
## Doesn't hold any data by itself, by its method should be overriden by
## subclasses to provide information about slot visuals.
class_name Slottable
extends Resource

@export var icon: Texture2D:
	get = _make_icon


func _make_icon() -> Texture2D:
	return icon
