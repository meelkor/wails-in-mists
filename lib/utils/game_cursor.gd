## Global helper for setting our custom cursors correctly, so we do not need to
## set the path/hotspot every time.

class_name GameCursor
extends Object


static func use_select_target() -> void:
	Input.set_custom_mouse_cursor(preload("res://resources/cursors/select_target.png"), Input.CursorShape.CURSOR_ARROW)


static func use_loot() -> void:
	Input.set_custom_mouse_cursor(preload("res://resources/cursors/loot.png"))


static func use_default() -> void:
	Input.set_custom_mouse_cursor(preload("res://resources/cursors/default.png"))


static func use_ng() -> void:
	Input.set_custom_mouse_cursor(preload("res://resources/cursors/ng.png"))
