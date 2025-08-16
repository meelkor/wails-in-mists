@tool
## Represents some "well known" term that has its own description, so we can
## easily reference it when it e.g. appears in text for tooltip. Example would
## be some lore term that appears in conversation that needs explanation.
class_name Term
extends Resource

@export var name: String

@export var description: String


func make_tooltip_content() -> RichTooltip.Content:
	var text_tooltip := RichTooltip.Content.new()
	text_tooltip.source = self
	var text_tooltip_title := RichTooltip.StyledLabel.new("[center]%s[/center]" % name, Config.Palette.TOOLTIP_TEXT_ACTIVE)
	text_tooltip.blocks.append(text_tooltip_title)
	var text_tooltip_content := RichTooltip.StyledLabel.new(description)
	text_tooltip_content.autowrap = true
	text_tooltip_content.margin_top = 8
	text_tooltip.blocks.append(text_tooltip_content)
	return text_tooltip
