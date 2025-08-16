extends EditorResourcePreviewGenerator


func _handles(type: String) -> bool:
	return type == "Resource"


func _generate(resource: Resource, size: Vector2i, metadata: Dictionary) -> Texture2D:
	var item := resource as Item
	if item:
		var icon := item.icon.get_image()
		var image := Image.create(size.x, size.y, true, Image.FORMAT_RGBA8)
		icon.resize(size.x, size.y)
		image.fill(Color("#1a1a1a"))
		image.blend_rect(icon, Rect2i(0, 0, icon.get_size().x, icon.get_size().y), Vector2i.ZERO)
		return ImageTexture.create_from_image(image)
	else:
		return null


func _can_generate_small_preview() -> bool:
	return true
