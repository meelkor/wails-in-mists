## Sync this subviewport's camera and window with the main viewport's
extends SubViewport

var di := DI.new(self)

@export var render_scale: float = 0.5

@onready var _parent_camera := di.inject(LevelCamera) as LevelCamera
@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
       match_root_viewport()
       get_window().size_changed.connect(match_root_viewport)
       _camera.fov = _parent_camera.fov


func _process(_delta: float) -> void:
       _camera.global_transform = _parent_camera.global_transform


func match_root_viewport() -> void:
       size = get_window().size * render_scale
