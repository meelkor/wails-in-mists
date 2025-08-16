@tool
extends EditorPlugin

const ResourcePreviewGenerator = preload("./resource_preview_generator.gd")

var _generator := ResourcePreviewGenerator.new()

func _enter_tree():
	_generator = ResourcePreviewGenerator.new()
	EditorInterface.get_resource_previewer().add_preview_generator(_generator)


func _exit_tree():
	EditorInterface.get_resource_previewer().remove_preview_generator(_generator)


