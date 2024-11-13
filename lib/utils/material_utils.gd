class_name MaterialUtils


static func set_last_pass(mesh: MeshInstance3D, new_material: Material) -> void:
	var cnt := mesh.get_surface_override_material_count()
	for i in range(0, cnt):
		var material := mesh.get_surface_override_material(i)
		while material.next_pass:
			material = material.next_pass
		material.next_pass = new_material
