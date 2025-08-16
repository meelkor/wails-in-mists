@abstract
class_name TerrainLines
extends Object

const DECALS_MATERIAL = preload("res://rust/src/fow/decals_postprocessing.tres")

const MAX_LINE_SIZE = 10


static func project_path(path: PackedVector3Array, color_len: float = 0, moved: float = 0, red_hl: Vector2 = Vector2()) -> void:
	if path.size() > 1:
		var line_path_info := Utils.Path.path3d_to_path2d(path, MAX_LINE_SIZE)
		DECALS_MATERIAL.set_shader_parameter("line_vertices", line_path_info["path"])
		DECALS_MATERIAL.set_shader_parameter("line_size", line_path_info["size"])
		DECALS_MATERIAL.set_shader_parameter("color_length", color_len)
		DECALS_MATERIAL.set_shader_parameter("line_red_segment", red_hl)
		DECALS_MATERIAL.set_shader_parameter("moved", moved)
	else:
		DECALS_MATERIAL.set_shader_parameter("line_size", 0)

