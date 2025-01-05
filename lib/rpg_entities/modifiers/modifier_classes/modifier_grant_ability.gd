## Modifier which grants set ability to character.
class_name ModifierGrantAbility
extends Modifier

@export var ability: Ability


func get_abilities(_c: GameCharacter, _source: ModifierSource) -> Array[AbilityGrant]:
	return [AbilityGrant.new(ability)]


func get_label() -> String:
	return "Grant %s" % ability.name


func make_tooltip_blocks() -> Array[RichTooltip.TooltipBlock]:
	var title := RichTooltip.StyledLabel.new("Grants ability", Config.Palette.TOOLTIP_TEXT_SECONDARY)
	title.size = Config.FontSize.SMALL

	var ability_line := RichTooltip.TooltipHeader.new()
	ability_line.label = RichTooltip.StyledLabel.new(ability.name, Config.Palette.TOOLTIP_TEXT_ACTIVE)
	ability_line.icon = ability.icon
	ability_line.icon_size = 32
	ability_line.link = ability.make_tooltip_content()

	return [
		title,
		ability_line,
	]
