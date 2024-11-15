## Base class for any kind of resource that can be used with slot containers.
## Doesn't hold any data by itself, by its method should be overriden by
## subclasses to provide information about slot visuals.
class_name Slottable
extends Resource


func get_icon() -> Texture2D:
	assert(false, "Slottable get_icon method not implemented")
	return null
