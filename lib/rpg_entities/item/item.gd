@tool
extends Slottable
class_name Item

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
}

@export var name: String:
	get = _make_name

@export var description: String

@export var flavor_text: String

@export var rarity: Rarity


## Defines text displayed with the item's name in its descriptive tooltip
func get_heading() -> String:
	return "Garbage"


## Create the most basic description of the item (icon, name, type...) and
## leave the rest for subclasses.
func make_tooltip_content() -> RichTooltip.Content:
	var content := RichTooltip.Content.new()
	content.source = self
	content.title = "Item"
	var header := RichTooltip.TooltipHeader.new()
	header.label = RichTooltip.StyledLabel.new(name)
	header.sublabel = RichTooltip.StyledLabel.new(get_heading(), Config.Palette.TOOLTIP_TEXT_SECONDARY)
	header.icon = icon
	content.blocks.append(header)
	return content


## Name getter so subclasses can implement their automatic name generation
func _make_name() -> String:
	return name


func _to_string() -> String:
	return "<Item:%s#%s>" % [name, get_instance_id()]
