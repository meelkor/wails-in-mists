extends Node3D


func _ready() -> void:
	var mdt = MeshDataTool.new()
	var mdt_orig = MeshDataTool.new()
	var skeleton = $metarig/Skeleton3D as Skeleton3D

	$AnimationPlayer.get_animation("run").loop_mode = Animation.LOOP_LINEAR
	$AnimationPlayer.play("run")

	# var mesh_orig = $metarig/Skeleton3D/Cube.mesh
	# var mesh = $metarig/Skeleton3D/Cube_002.mesh
	# mdt.create_from_surface(mesh, 0)
	# mdt_orig.create_from_surface(mesh_orig, 0)

	# var closest_index: int = 0
	# var closest_distance: float = 100000
	# for i in range(mdt.get_vertex_count()):
	# 	var vertex = mdt.get_vertex(i)
	# 	for l in range(mdt_orig.get_vertex_count()):
	# 		var vertex_orig = mdt_orig.get_vertex(l)
	# 		var d = vertex_orig.distance_squared_to(vertex)
	# 		if d < closest_distance:
	# 			closest_index = l
	# 			closest_distance = d

	# 	mdt.set_vertex_bones(i, mdt_orig.get_vertex_bones(closest_index))
	# 	mdt.set_vertex_weights(i, mdt_orig.get_vertex_weights(closest_index))

	# mesh.clear_surfaces()
	# mdt.commit_to_surface(mesh)

	# $metarig/Skeleton3D/Cube_002.mesh = mesh

func _process(delta):
	$metarig.rotate_y(delta * PI * 0.5)
