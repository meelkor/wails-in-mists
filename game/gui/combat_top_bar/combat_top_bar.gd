## Bar displayed above combat participant portaitrs as if "holding them"
extends Control

@onready var _mask := $Mask as Polygon2D
@onready var _border_start := $BorderStart as Control
@onready var _border_end := $BorderEnd as Control
@onready var _texture_rect := $Mask/TextureRect as TextureRect


## Update the control's width manually since it uses Node2D for mask which
## doesn't respect controls.
func set_width(width: float) -> void:
	custom_minimum_size.x = width
	_texture_rect.custom_minimum_size.x = width
	_mask.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(width, 0),
		Vector2(width - 8, 8),
		Vector2(8, 8),
	])
	_border_start.position.x = 0
	# todo: currently scale is used to support multi-resolution since I found
	# no way to do y-scale, x-repeat. Thus the / 2
	_border_end.position.x = width - _border_end.size.x / 2
