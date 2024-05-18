class_name MaterialUtils

static func set_last_pass(mesh: Mesh, new_material: Material) -> void:
	for i in range(0, mesh.get_surface_count()):
		var material = mesh.surface_get_material(i)
		while material.next_pass:
			material = material.next_pass
		material.next_pass = new_material
