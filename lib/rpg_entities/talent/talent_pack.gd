class_name TalentPack
extends Resource

@export var talents: Array[Talent]


func _init(i_talents: Array[Talent] = []) -> void:
	talents = i_talents
