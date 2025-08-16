## Utility class for passing which circles should be rendered this frame on the
## terrain. Primarily used to display character selection circles by controls
## nodes.
class_name CircleProjector
extends RefCounted

const PROJECT_MATERIAL = preload("res://materials/terrain_projections.tres")

var positions := PackedVector4Array([Vector4.ZERO])
var colors := PackedVector4Array([Vector4.ZERO])
var extras := PackedVector4Array([Vector4.ZERO])

var i := 1


## Add custom circles for characters with given circle parameters
func add_characters(chars: Array, opacity: float = 1.0, dash: float = 1.0) -> void:
	for character: GameCharacter in chars:
		add_circle(character.position, character.model_radius, Utils.Vector.rgb(character.get_color()), opacity, -1.0, dash)


## Display standard selection circles for given characters that are selected.
func add_selected_characters(chars: Array[PlayableCharacter]) -> void:
	for character in chars:
		if character.selected:
			add_circle(character.position, character.model_radius, Utils.Vector.rgb(character.get_color()))


## Add circle with given parameters
func add_circle(position: Vector3, radius: float, color: Vector3, opacity: float = 1.0, inner_fade: float = -1.0, dashed: float = 1.0) -> void:
	var full_color := Vector4(color.x, color.y, color.z, opacity)
	var full_pos := Vector4(position.x, position.y, position.z, radius)
	var full_extras := Vector4(dashed, inner_fade, 0.0, 0.0)
	if i == positions.size():
		positions.append(full_pos)
		colors.append(full_color)
		extras.append(full_extras)
	else:
		positions[i] = full_pos
		colors[i] = full_color
		extras[i] = full_extras
	i += 1


## Apply added circles to the shader material. Needs to be called after all
## circles were added to take effect.
func apply() -> void:
	PROJECT_MATERIAL.set_shader_parameter("circle_positions", ImageTexture.create_from_image(Image.create_from_data(i, 1, false, Image.FORMAT_RGBAF, positions.slice(0, i).to_byte_array())))
	PROJECT_MATERIAL.set_shader_parameter("circle_colors", ImageTexture.create_from_image(Image.create_from_data(i, 1, false, Image.FORMAT_RGBAF, colors.slice(0, i).to_byte_array())))
	PROJECT_MATERIAL.set_shader_parameter("circle_extras", ImageTexture.create_from_image(Image.create_from_data(i, 1, false, Image.FORMAT_RGBAF, extras.slice(0, i).to_byte_array())))
	PROJECT_MATERIAL.set_shader_parameter("circle_count", i)


## Should be called before any circle is added.
func reset() -> void:
	i = 1


func clear() -> void:
	reset()
	apply()
