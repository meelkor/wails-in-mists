@tool
extends EditorScenePostImport

@export var material_path: String

func _post_import(scene: Node):
	return scene.find_children("", "MeshInstance3D")[0]
