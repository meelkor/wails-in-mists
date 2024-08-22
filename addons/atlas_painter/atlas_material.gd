## Material which creates atlas texture and displays textures from it
## (optionally with 2 textures blended together) according to the atlas that
## may be edited using the editor plugin.
##
## TODO: save the final compressed textures when exporting project
@tool
class_name AtlasMaterial
extends ShaderMaterial


## Textures in the final atlas. Normal may may also be included
@export var textures: Array[AtlasImage] = []:
	set(v):
		textures = v
		for tex in v:
			if tex and not tex.changed.is_connected(_update_textures):
				tex.changed.connect(_update_textures)
		_update_textures()

@export var atlas_map: Image:
	set(v):
		atlas_map = v
		_update_textures()
		_listen_to_atlas_map_changes()

var _atlas_texture: ImageTexture

var _atlas_normal_texture: ImageTexture

var _atlas_map_texture: ImageTexture


func _init() -> void:
	shader = preload("./atlas_shader.gdshader")
	_listen_to_atlas_map_changes()
	_update_textures()


## Do not export the shader so it cannot be unintionaly modified
func _validate_property(property: Dictionary):
	if property["name"] == "shader":
		property.usage = PROPERTY_USAGE_RESOURCE_NOT_PERSISTENT


func _listen_to_atlas_map_changes() -> void:
	if atlas_map:
		atlas_map.changed.connect(func(): _update_textures())


## Generate the final textures required by the shader and upload them to GPU.
func _update_textures():
	var offset_x: int = 0
	if textures:
		var has_normal = false
		var atlas_image = Image.create_empty(512 * textures.size(), 512, false, Image.Format.FORMAT_RGBA8)
		var normal_image = Image.create_empty(512 * textures.size(), 512, false, Image.Format.FORMAT_RGBA8)
		for tex in textures:
			if tex:
				if tex.albedo:
					atlas_image.blit_rect(tex.albedo, Rect2i(0, 0, 512, 512), Vector2i(offset_x * 512, 0))
				if tex.normal:
					has_normal = true
					normal_image.blit_rect(tex.normal, Rect2i(0, 0, 512, 512), Vector2i(offset_x * 512, 0))
				offset_x += 1
		_atlas_texture = ImageTexture.create_from_image(atlas_image)
		if has_normal:
			_atlas_normal_texture = ImageTexture.create_from_image(normal_image)
	if atlas_map:
		_atlas_map_texture = ImageTexture.create_from_image(atlas_map)

	set_shader_parameter("texture_count", offset_x)
	set_shader_parameter("texture_atlas", _atlas_texture)
	set_shader_parameter("texture_normal_atlas", _atlas_normal_texture)
	set_shader_parameter("texture_map", _atlas_map_texture)
	emit_changed()


## Hack to ensure shader params are not saved in the material, since those are
## dynamically created.
func _get(property: StringName) -> Variant:
	if property == "shader_parameter/texture_atlas" or property == "shader_parameter/texture_normal_atlas" or property == "shader_parameter/texture_map":
		return 0
	else:
		return null
