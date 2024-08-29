## Base class for any kind of resource that can be used with slot containers.
## Doesn't hold any data by itself, by its method should be overriden by
## subclasses to provide information about slot visuals.
class_name Slottable
extends Resource

## Temp solution since I dunno how the icon info is gonna be stored. In the
## future I should prolly use the overriden render method instead??
@export var icon: Texture2D


## Called when rendering a slot button which should contain this resource.
func render(_btn: SlotButton) -> void:
	pass
