class_name Utils
extends Object

class Path:
	extends Object

	## Convert 3D path to 2D discaring the y coordinate and dropping less
	## significant steps (steps where the angle changes just by few degrees or
	## very short steps). Such path should only be used for visualization.
	static func path3d_to_path2d(path3d: PackedVector3Array, size: int) -> PackedVector2Array:
		# Min angle between two path segment to actually include the segment in
		# returned path
		const MIN_ANGLE = 0.04 * PI
		# Min length of the path segment to be included in the retruned path [m]
		const MIN_SEGMENT_LENGTH = 0.1

		var last_point_2d = Math.vec3_xz(path3d[-1])
		var path2d = PackedVector2Array()
		path2d.resize(size)
		path2d.fill(last_point_2d)
		path2d[0] = Math.vec3_xz(path3d[0])
		path2d[1] = Math.vec3_xz(path3d[1])

		var path2d_i = 2
		var last_angle: float = -30

		for i in range(2, path3d.size()):
			var new_point = Vector2(path3d[i].x, path3d[i].z)
			var prev_point = path2d[path2d_i - 1]
			var current_angle = (new_point - prev_point).angle_to(Vector2.RIGHT)
			var very_short = new_point.distance_to(prev_point) < MIN_SEGMENT_LENGTH
			var same_direction = abs(last_angle - current_angle) < MIN_ANGLE
			last_angle = current_angle

			if same_direction or very_short:
				path2d[path2d_i - 1] = new_point
			else:
				path2d[path2d_i] = new_point
				path2d_i += 1
				if path2d_i == path2d.size():
					break

		return path2d

	## Remove all points in the path3d that do not have corresponding
	## counterpart (in x,z) in the fitler path.
	static func filter_3d_by_2d(path3d: PackedVector3Array, filter: PackedVector2Array) -> PackedVector3Array:
		var last_optimized_point = filter[-1];
		for i in range(0, path3d.size()):
			var vec = path3d[i]
			if last_optimized_point.x == vec.x and last_optimized_point.y == vec.z:
				return path3d.slice(0, i + 1)
		assert(false, "Panic: _filter_by_optimized didn't find the last point in original array")
		return PackedVector3Array() # just to make compiler happy