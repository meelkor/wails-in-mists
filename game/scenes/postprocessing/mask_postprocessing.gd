## Adds postprocessing to the level's screen which renders mask for occluded
## objects. Not used, kept so I can test performance compared to the depth
## material thing.
##
## Haven't tested since I moved it into separate scene
extends Node

const MATERIAL = preload("res://scenes/postprocessing/mask_viweport_material.tres")

var di := DI.new(self)

@export var render_scale: float = 0.5

@onready var _level := di.inject(BaseLevel) as BaseLevel
@onready var _viewport: SubViewport = $CameraSyncedViewport


func _ready() -> void:
	var screen := _level.get_node("./Screen") as MeshInstance3D
	screen.material_overlay = MATERIAL


func _process(_delta: float) -> void:
	var img := _viewport.get_texture().get_image()
	var tex := ImageTexture.create_from_image(img)
	MATERIAL.set_shader_parameter("character_mask", tex)
