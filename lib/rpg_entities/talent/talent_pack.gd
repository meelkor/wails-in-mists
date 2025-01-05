class_name TalentPack
extends Slottable

@export var talents: Array[Talent]


func _init(i_talents: Array[Talent] = []) -> void:
	talents = i_talents


## Get list of contained talent names
func get_summary() -> Array[String]:
	var summary: Array[String] = []
	for talent in talents:
		summary.append(talent.name)
	return summary


func make_tooltip_content() -> RichTooltip.Content:
	var content := RichTooltip.Content.new()
	content.title = "Talent"
	content.source = self
	for talent in talents:
		content.blocks.append(RichTooltip.StyledLabel.new(talent.name))
		for modifier in talent.modifiers:
			content.blocks.append_array(modifier.make_tooltip_blocks())
	return content
