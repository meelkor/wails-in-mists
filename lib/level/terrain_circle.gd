## Node which provides circles for the terrain circle projection pass
class_name TerrainCircle
extends Node3D

## Whether any of the circles/properties changed. This node only takes care of
## setting it on, reset to false should happen by node that displays the
## circle.
static var changed := true

## Packed positions+radius for all visible circles: (x, y, z, radius)
static var _positions := PackedVector4Array([Vector4.ZERO])

## Packed colors for all visible circles (r, g, b, a)
static var _colors := PackedVector4Array([Vector4.ZERO])

## Packed extra info about all visible circles: (dashed, inner_fade, _, _)
static var _extras := PackedVector4Array([Vector4.ZERO])

## References to all displayed circles, where circle's index represents the
## index-1 in the packed arrays.
static var _circles: Array[TerrainCircle] = []


static func get_count() -> int:
	return _positions.size()


static func get_positions_tex() -> ImageTexture:
	return ImageTexture.create_from_image(Image.create_from_data(_positions.size(), 1, false, Image.FORMAT_RGBAF, _positions.to_byte_array()))


static func get_colors_tex() -> ImageTexture:
	return ImageTexture.create_from_image(Image.create_from_data(_colors.size(), 1, false, Image.FORMAT_RGBAF, _colors.to_byte_array()))


static func get_extras_tex() -> ImageTexture:
	return ImageTexture.create_from_image(Image.create_from_data(_extras.size(), 1, false, Image.FORMAT_RGBAF, _extras.to_byte_array()))


static func make_for_character(chara: GameCharacter, alpha: float = 1.0) -> TerrainCircle:
	var ctrl := chara.get_controller()
	var circle := TerrainCircle.new()
	circle.color = Color(chara.get_color(), alpha)
	circle.radius = chara.model_radius
	circle.track_node(ctrl)
	return circle


static func _add(circle: TerrainCircle) -> void:
	_positions.append(Vector4.ZERO)
	_colors.append(Vector4.ZERO)
	_extras.append(Vector4.ZERO)
	_circles.append(circle)
	circle._index = _circles.size() # index in _circles + 1
	_update_position(circle)
	_update_radius(circle)
	_update_color(circle)
	_update_extras(circle)


static func _remove(circle: TerrainCircle) -> void:
	_circles.erase(circle)
	_positions.resize(_circles.size() + 1)
	_colors.resize(_circles.size() + 1)
	_extras.resize(_circles.size() + 1)
	for i in range(0, _circles.size()):
		_circles[i]._index = i + 1
		_update_position(_circles[i])
		_update_radius(_circles[i])
		_update_color(_circles[i])
		_update_extras(_circles[i])


static func _update_position(circle: TerrainCircle, source: Node3D = circle) -> void:
	_positions[circle._index].x = source.global_position.x
	_positions[circle._index].y = source.global_position.y
	_positions[circle._index].z = source.global_position.z
	TerrainCircle.changed = true


static func _update_radius(circle: TerrainCircle) -> void:
	_positions[circle._index].w = circle.radius
	TerrainCircle.changed = true


static func _update_color(circle: TerrainCircle) -> void:
	_colors[circle._index] = Utils.Vector.rgba(circle.color)
	TerrainCircle.changed = true


static func _update_extras(circle: TerrainCircle) -> void:
	_extras[circle._index].x = circle.dashed
	_extras[circle._index].y = circle.fade
	TerrainCircle.changed = true


###############################################################################

## Radius of the circle in meters
@export var radius: float = 1.:
	set(v):
		radius = v
		if is_inside_tree():
			TerrainCircle._update_radius(self)

## Color of the circle
@export var color: Color:
	set(v):
		color = v
		if is_inside_tree():
			TerrainCircle._update_color(self)

## Opacity of the fade from circle's border to its origin
@export_range(0.0, 1.0) var fade: float:
	set(v):
		fade = v
		if is_inside_tree():
			TerrainCircle._update_extras(self)

## The amount of dashed effect. 0 is solid line.
@export var dashed: int:
	set(v):
		dashed = v
		if is_inside_tree():
			TerrainCircle._update_extras(self)


## Index in the static vec4 arrays, set by the static register
var _index: int = -1

## Node from which a transform should be read on every frame.
var _tracked_node: Node3D


func track_node(node: Node3D) -> void:
	_tracked_node = node


func _ready() -> void:
	set_notify_transform(true)
	if _tracked_node:
		global_position = _tracked_node.global_position


func _process(_delta: float) -> void:
	if _tracked_node and _tracked_node.global_position != global_position:
		global_position = _tracked_node.global_position


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		TerrainCircle._update_position(self)


func _enter_tree() -> void:
	TerrainCircle._add(self)


func _exit_tree() -> void:
	TerrainCircle._remove(self)
