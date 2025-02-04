@tool
class_name Utils
extends Object

static var _collision_layers: Dictionary[String, int]


static func _static_init() -> void:
	var layer_name: String
	for i in range(1, 21):
		layer_name = ProjectSettings.get_setting("layer_names/3d_physics/layer_" + str(i))
		if len(layer_name) > 0:
			_collision_layers[layer_name] = i


## Get colision layer mask by layer name defined in project settings
static func get_collision_layer(layer_name: String) -> int:
	return 1 << (_collision_layers[layer_name] - 1)


## Create Shortcut instance that can be used with BaseButtons
static func get_action_shortcut(action: String) -> Shortcut:
	var shortcut := Shortcut.new()
	var shortcut_event := InputEventAction.new()
	shortcut_event.action = action
	shortcut.events.append(shortcut_event)
	return shortcut


class Dict:
	extends Object

	static func assign(dst_obj: Object, src_dict: Dictionary) -> void:
		for key: String in src_dict:
			dst_obj.set(key, src_dict[key])


class Nodes:
	extends Object


	## Remove and free all children in given node
	static func clear_children(node: Node) -> void:
		for child in node.get_children():
			node.remove_child(child)
			child.queue_free()


	static func remove_self(node: Node) -> void:
		node.get_parent().remove_child(node)
		node.queue_free()


class Mouse:
	extends Object


class Path:
	extends Object

	## Convert 3D path to 2D discaring the y coordinate and dropping less
	## significant steps (steps where the angle changes just by few degrees or
	## very short steps). Such path should only be used for visualization.
	static func path3d_to_path2d(path3d: PackedVector3Array, size: int) -> Dictionary:
		# Min angle between two path segment to actually include the segment in
		# returned path
		const MIN_ANGLE := 0.04 * PI
		# Min length of the path segment to be included in the retruned path [m]
		const MIN_SEGMENT_LENGTH := 0.1

		var last_point_2d := Utils.Vector.xz(path3d[-1])
		var path2d := PackedVector2Array()
		path2d.resize(size)
		path2d.fill(last_point_2d)
		path2d[0] = Utils.Vector.xz(path3d[0])

		var path2d_i := 1
		var last_angle: float = -30

		for i in range(1, path3d.size()):
			var new_point := Utils.Vector.xz(path3d[i])
			var prev_point := path2d[path2d_i - 1]
			var very_short := new_point == prev_point or new_point.distance_to(prev_point) < MIN_SEGMENT_LENGTH
			var current_angle := (new_point - prev_point).angle_to(Vector2.RIGHT)
			var same_direction: bool = abs(last_angle - current_angle) < MIN_ANGLE
			last_angle = current_angle

			if new_point == last_point_2d or not same_direction and not very_short:
				path2d[path2d_i] = new_point
				path2d_i += 1
				if path2d_i == path2d.size():
					break

		return {
			"path": path2d,
			"size": path2d_i,
		}

	## Remove all points in the path3d that do not have corresponding
	## counterpart (in x,z) in the fitler path.
	static func filter_3d_by_2d(path3d: PackedVector3Array, filter: PackedVector2Array) -> PackedVector3Array:
		var last_optimized_point := filter[-1];
		for i in range(0, path3d.size()):
			var vec := path3d[i]
			if last_optimized_point.x == vec.x and last_optimized_point.y == vec.z:
				return path3d.slice(0, i + 1)
		assert(false, "Panic: _filter_by_optimized didn't find the last point in original array")
		return PackedVector3Array() # just to make compiler happy


class Vector:
	extends Object

	static func rgb(cl: Color) -> Vector3:
		return Vector3(cl.r, cl.g, cl.b)

	static func rgba(cl: Color) -> Vector4:
		return Vector4(cl.r, cl.g, cl.b, cl.a)

	## Basically vec(3|4).xz
	static func xz(vector: Variant) -> Vector2:
		return Vector2(vector.x as float, vector.z as float)
