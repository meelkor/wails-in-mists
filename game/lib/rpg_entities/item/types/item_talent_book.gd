## Class for talent book items - consumable which grants assigned talentpack to
## the selected character.
@tool
class_name ItemTalentBook
extends ItemConsumable

@export var pack: TalentPack


func get_heading() -> String:
	return "Talent book"


func on_use(character: GameCharacter) -> bool:
	# todo: show "are you sure character {} should learn this talent?" confirm
	# dialog
	var pc := character as PlayableCharacter
	if pc:
		pc.available_talents.add_entity(pack)
		# todo: play some level-up-like animation
		return true
	return false


func make_tooltip_content() -> RichTooltip.Content:
	# content with header
	var content := super.make_tooltip_content()
	var desc := RichTooltip.StyledLabel.new("Using this item grants currently selected character following talent. Book disappears once it's used.", Config.Palette.TOOLTIP_TEXT_SECONDARY)
	desc.margin_top = 4
	desc.autowrap = true
	content.blocks.append(desc)
	content.append_content(pack.make_tooltip_content())
	return content


func _make_name() -> String:
	return name if name else ", ".join(pack.get_summary())
