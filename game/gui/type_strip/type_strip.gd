@tool
extends MarginContainer

@export var text: String = "":
	set(v):
		text = v
		_ready()

@export var disabled: bool = false:
	set(v):
		disabled = v
		_ready()

@onready var _label := $Label as Label
@onready var _polygon := $Polygon2D as Polygon2D


func _ready() -> void:
	if is_inside_tree():
		_label.text = text
		_polygon.color = Color(0.5, 0.5, 0.5) if disabled else Color.WHITE
		if disabled:
			_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))


func _notification(what: int) -> void:
	if what == Control.NOTIFICATION_RESIZED:
		var unit := size.y / 2
		var vertices := [
			Vector2(0, 0),
			Vector2(size.x, 0),
			Vector2(size.x + unit, size.y / 2),
			Vector2(size.x, size.y),
			Vector2(0, size.y),
			Vector2(unit, size.y / 2),
		]
		_polygon.polygon = PackedVector2Array(vertices)
		_polygon.uv = PackedVector2Array(vertices.map(func (vec: Vector2) -> Vector2: return vec * 2))

