## Dock with options for the texture painter
@tool
extends VBoxContainer

signal reset()

var _config: AtlasPainterConfig


## Set config which the dock should control
func set_config(cfg: AtlasPainterConfig) -> void:
	_config = cfg
	(%SizeSlider as HSlider).value = _config.brush_size
	(%StrengthSlider as HSlider).value = _config.brush_strength
	(%FadeSlider as HSlider).value = _config.brush_fade
	_update_texture_options()

	# hacky solution, introduce some in the material itself
	var last_texs = cfg.material.textures
	cfg.material.changed.connect(func ():
		if last_texs != cfg.material.textures or last_texs.size() != cfg.material.textures.size():
			_update_texture_options()
			last_texs = cfg.material.textures
	)


## List available texture in the option buttton.
func _update_texture_options():
	var select := (%TextureSelect as OptionButton)
	select.clear()
	for i in range(_config.material.textures.size()):
		var img := _config.material.textures[i]
		if img and img.albedo:
			var texture = ImageTexture.create_from_image(img.albedo)
			texture.set_size_override(Vector2i(64, 64))
			select.add_icon_item(texture, img.resource_name, i)
	select.selected = _config.texture


func _on_strength_slider_value_changed(value: float) -> void:
	%StrengthLabel.text = str(value)
	_config.brush_strength = int(value)


func _on_reset_btn_pressed() -> void:
	reset.emit()


func _on_size_slider_value_changed(value: float) -> void:
	%SizeLabel.text = str(value)
	_config.brush_size = int(value)


func _on_fade_slider_value_changed(value: float) -> void:
	%FadeLabel.text = str(round(_config.brush_fade * 100) / 100.0)
	_config.brush_fade = value


func _on_texture_select_main_x_item_selected(index: int) -> void:
	_config.texture = index
