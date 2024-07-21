extends Node3D


func _ready() -> void:
	var skeleton: Skeleton3D = find_child("Skeleton3D")
	var bones = skeleton.find_children("", "PhysicalBone3D")
	for bone in bones:
		if bone is PhysicalBone3D:
			bone.collision_mask = 0b10110
			bone.collision_layer = 0b10000
	skeleton.physical_bones_start_simulation()
