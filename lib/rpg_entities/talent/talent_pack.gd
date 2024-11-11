class_name TalentPack
extends Slottable

@export var talents: Array[Talent]


func _init(i_talents: Array[Talent] = []) -> void:
	talents = i_talents


## Get list of contained talent names
func get_summary() -> Array[String]:
	var summary: Array[String] = []
	for talent in talents:
		summary.append(talent.name())
	return summary
