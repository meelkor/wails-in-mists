## Some items may need extra properties that are then added to the referenced
## Item instance, which basically works as a template. Otherwise we'd need to
## modify the loaded item resources, which should be constant.
class_name ItemRef
extends Slottable

## Referenced item
var item: Item

func _init(i_item: Item) -> void:
	item = i_item
	icon = item.icon
