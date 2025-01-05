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


func make_tooltip_content() -> RichTooltip.Content:
	var content := RichTooltip.Content.new()
	content.source = self
	content.title = "Item"
	var header := RichTooltip.TooltipHeader.new()
	header.label = RichTooltip.StyledLabel.new(item.name)
	header.sublabel = RichTooltip.StyledLabel.new(item.get_heading(), Config.Palette.TOOLTIP_TEXT_SECONDARY)
	header.icon = item.icon
	content.blocks.append(header)
	return content


func _make_icon() -> Texture2D:
	return item.icon
