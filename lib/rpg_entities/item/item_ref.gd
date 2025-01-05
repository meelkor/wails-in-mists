## Some items may need extra properties that are then added to the referenced
## Item instance, which basically works as a template. Otherwise we'd need to
## modify the loaded item resources, which should be constant.
class_name ItemRef
extends Slottable

## Referenced item
@export var item: Item


func _init(i_item: Item = null) -> void:
	if i_item:
		item = i_item


func _make_icon() -> Texture2D:
	return item.icon
