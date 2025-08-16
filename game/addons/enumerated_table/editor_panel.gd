@tool
extends VBoxContainer

var save_dialog = EditorFileDialog.new()

func _enter_tree() -> void:
	add_child(save_dialog)
	save_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	save_dialog.owner = self
	save_dialog.file_selected.connect(_on_new_table_enum_file_selected)
	save_dialog.add_filter("*.tres")


func _ready():
	_update_content()


func _update_content() -> void:
	while $ContentContainer.get_child_count() > 0:
		$ContentContainer.remove_child($ContentContainer.get_child(0))

	var res_fs = EditorInterface.get_resource_filesystem()
	var dir = res_fs.get_filesystem()
	var tables = _find_resources_of_type(dir, EnumeratedTable)

	for table_path in tables.keys():
		var table = tables[table_path]
		var table_editor = preload("res://addons/enumerated_table/table_section.tscn").instantiate()
		table_editor.table = table
		table_editor.table_path = table_path
		$ContentContainer.add_child(table_editor)


## Find all resources of given type throughout given directory recursively.
func _find_resources_of_type(dir: EditorFileSystemDirectory, clss) -> Dictionary[String, Resource]:
	var results: Dictionary[String, Resource] = {}
	for fi in range(dir.get_file_count()):
		var file_type = dir.get_file_type(fi)
		if file_type == "Resource":
			var res_path = dir.get_file_path(fi)
			var res = load(res_path)
			if is_instance_of(res, clss):
				results[res_path] = res
	for idx in range(dir.get_subdir_count()):
		results.merge(_find_resources_of_type(dir.get_subdir(idx), clss))
	return results


func _on_add_new_clicked() -> void:
	save_dialog.popup_centered(Vector2i(900, 700))


func _on_update_pressed() -> void:
	_update_content()


func _on_new_table_enum_file_selected(file_path: String) -> void:
	var new_enum = EnumeratedTable.new()
	new_enum.name = "New Table Enum"
	ResourceSaver.save(new_enum, file_path)
