## Structure for communication between the editor's dock and the actual painter
## logic.
class_name AtlasPainterConfig
extends RefCounted

var brush_size: int = 5
## Opacity
var brush_strength: int = 255
## How quickly the brush fades into transparency
var brush_fade: float = 10
## Index of a texture we are painting
var texture: int = 0

## Material provided so we can list all texture in the dock
var material: AtlasMaterial

func _init(edited_material: AtlasMaterial):
	material = edited_material
