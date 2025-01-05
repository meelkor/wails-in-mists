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


## Inherit the tooltip content from referenced item
func make_tooltip_content() -> RichTooltip.Content:
	var content := item.make_tooltip_content()
	content.source = self
	return content


func _make_icon() -> Texture2D:
	return item.icon
