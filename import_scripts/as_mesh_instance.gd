# To be used when importing GLB with single mesh whose instance is then used as
# the root of the create scene.
@tool
extends EditorScenePostImport

@export var material_path: String

func _post_import(scene: Node):
	return scene.find_children("", "MeshInstance3D")[0]
