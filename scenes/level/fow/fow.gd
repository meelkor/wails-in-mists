class_name Fow
extends MeshInstance3D

const PX_PER_METER = 8
const SIGHT_DISANCE_M = 10
const SIGHT_DISANCE_PX_SQUARED = (SIGHT_DISANCE_M * PX_PER_METER) ** 2

const UNEXPLORED_VALUE = Color(0, 0, 0, 1)
const EXPLORED_VALUE = Color(0, 0, 0, 0.5)
const OBSERVED_VALUE = Color(0, 0, 0, 0)

var image_data: PackedByteArray;
var image: Image

var width_px: int;
var height_px: int;

func setup(terrain_aabb: AABB):
	var test: Array[Vector3] = [Vector3(11, 30, 40)]
	var width_m = ceil(terrain_aabb.size.x)
	var height_m = ceil(terrain_aabb.size.z)
	position = terrain_aabb.position
	scale.x = width_m
	scale.y = 1
	scale.z = height_m

	var test_pos = Vector2(0, 0)

	width_px = PX_PER_METER * width_m
	height_px = PX_PER_METER * height_m

	image_data = PackedByteArray()
	image_data.resize(width_px * height_px)
	image_data.fill(255)

	_update_image_for_pos([test_pos])
	_upload_texture()

func update(sight_positions: Array[Vector3]):
	if _update_image_for_pos(sight_positions):
		_upload_texture()

func _update_image_for_pos(positions: Array[Vector3]) -> bool:
	var changed: bool = false
	for pos in positions:
		for i in range(0, image_data.size()):
			var x = i % width_px
			var y = floor(i / width_px)
			var current = image_data[i]
			var observed = (pos.x - x) ** 2 + (pos.y - y) ** 2 < SIGHT_DISANCE_PX_SQUARED
			if observed:
				if current != 255:
					image_data.set(i, 255)
					changed = true
			elif current == 255:
				image_data.set(i, 100)
				changed = true
	return changed


# Update its own texture with the data in tex_data variable
func _upload_texture():
	var image = Image.create_from_data(width_px, height_px, false, Image.FORMAT_R8, image_data)
	var tex = ImageTexture.create_from_image(image)
	(mesh.surface_get_material(0) as StandardMaterial3D).albedo_texture = tex


func _on_controlled_characters_position_changed(positions: Array[Vector3]) -> void:
	update(positions)
