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

	# todo: it should be a small line with hypertext link to the full ability
	# tooltip
	return [
		title,
		ability.make_tooltip_content().blocks[0],
	]
