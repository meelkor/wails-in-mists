@tool
class_name CharacterAttribute
extends Resource

@export var name: String

@export var attribute_color_long: String

@export var description: String = ""

## Position of this attribute on atlas textures which contain
@export var atlas_position: int = 1

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
