## Attempt at rendering characters behind objects. Render characters in
## viewport and provide that texture to meshe instances and multimeshes in
## character_masked group
extends SubViewport

var di = DI.new(self)

@onready var _parent_camera = di.inject(LevelCamera)
@onready var _camera: Camera3D = $Camera3D

var _char_mask_material: ShaderMaterial = preload("res://materials/character_masked/character_masked.tres")

func _ready() -> void:
	match_root_viewport()
	get_window().size_changed.connect(match_root_viewport)

	_camera.fov = _parent_camera.fov
	var masked_nodes = get_tree().get_nodes_in_group("character_masked")
	for node in masked_nodes:
		var mesh: Mesh
		if node is MeshInstance3D:
			mesh = node.mesh
		elif node is MultiMeshInstance3D:
			mesh = node.multimesh.mesh
		MaterialUtils.set_last_pass(mesh, _char_mask_material)

func _process(_delta: float) -> void:
	_camera.global_transform = _parent_camera.global_transform
	var img = get_texture().get_image()
	var tex = ImageTexture.create_from_image(img)
	_char_mask_material.set_shader_parameter("character_mask", tex)

func match_root_viewport() -> void:
	size = get_window().size * 0.5
