## Represents a singe section in the editor, editing of single EnumeratedTable
## resource
@tool
extends VBoxContainer

var table: EnumeratedTable

var table_path: String

var rows: Array[ResourceRow] = []


func _ready() -> void:
	if table:
		var picker = EditorResourcePicker.new()
		var picker_label = Label.new()
		picker.base_type = "GDScript"
		picker.edited_resource = table.child_type
		picker_label.text = table.child_type.resource_path if table.child_type else ""
		picker.resource_changed.connect(func (res):
			picker_label.text = res.resource_path
			table.child_type = res
		)
		%TableTitle.add_sibling(picker)
		%TableTitle.add_sibling(picker_label)
		%TableTitle.text = table_path
		%NameEdit.text = table.name
		%PrefixEdit.text = table.prefix
		if table.child_type:
			_read_data()
			_update_content()


func _update_name(new_name) -> void:
	table.name = new_name


func _on_save_button_pressed() -> void:
	var res_fs = EditorInterface.get_resource_filesystem()
	ResourceSaver.save(table, table_path)
	for row in rows:
		var newpath = table_path.get_base_dir().path_join(table.prefix_str(row.id + ".tres"))
		if row.orig_path and row.orig_id != row.id:
			print("Removing %s" % row.orig_path)
			DirAccess.remove_absolute(row.orig_path)
			row.orig_path = newpath
			row.orig_id = row.id
		ResourceSaver.save(row.resource, newpath)
	var enum_script = _build_enum_script()
	ResourceSaver.save(enum_script, table_path.get_base_dir().path_join("%s.gd" % table.name.to_snake_case()))
	res_fs.scan()


func _build_enum_script():
	var lines = [
		"## This file was autogenerated using the EnumreatedTable plugin.",
		"## Do not edit manually!",
		"class_name %s" % table.name,
		"extends Object",
		"",
		"",
	]
	for row in rows:
		var snake = row.id
		var const_name = row.id.to_upper()
		lines.append("static var %s = preload(\"%s\")" % [const_name, row.orig_path])
	if rows.size() > 0:
		lines.append("")
		lines.append("func get_all() -> Array[%s]:" % _get_class_name(table.child_type))
		lines.append("    return [")
		for row in rows:
			var const_name = row.id.to_upper()
			lines.append("        %s," % [const_name])
		lines.append("    ]")
	lines.append("")
	var enum_script = GDScript.new()
	enum_script.source_code = "\n".join(lines)
	return enum_script


func _get_class_name(script: GDScript) -> String:
	var lines = script.source_code.split("\n")
	for line in lines:
		if line.begins_with("class_name"):
			return line.replace("class_name ", "")
	return ""


## Read all resource siblings to this table's resource files that are of edited
## type and store them in the data dir
func _read_data() -> void:
	var res_fs = EditorInterface.get_resource_filesystem()
	var dir = res_fs.get_filesystem_path(table_path.get_base_dir())
	for fi in range(dir.get_file_count()):
		var file_path = dir.get_file_path(fi)
		var file_name = file_path.get_file()
		var file_type = dir.get_file_type(fi)
		var full_prefix = table.prefix_str("")
		if file_type == "Resource" and file_name.begins_with(full_prefix):
			var res = load(file_path)
			if is_instance_of(res, table.child_type):
				var row = ResourceRow.new()
				row.id = file_name.get_basename().trim_prefix(full_prefix)
				row.orig_id = row.id
				row.resource = res
				row.orig_path = file_path
				rows.append(row)


func _update_content() -> void:
	while $ContentContainer.get_child_count() > 0:
		$ContentContainer.remove_child($ContentContainer.get_child(0))

	for row_i in range(0, rows.size()):
		var row = rows[row_i]
		var data = row.resource
		var row_container = HBoxContainer.new()
		var row_label = Label.new()
		row_label.text = "#%s" % row_i
		row_container.add_child(row_label)

		add_column(row_container, "ID", row.id, 100).connect(func (val): row.id = val)

		for prop in data.get_property_list():
			if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE > 0:
				add_column(row_container, prop["name"], data.get(prop["name"])).connect(func (val): data.set(prop["name"], val))

		var remove_btn = Button.new()
		remove_btn.icon = EditorInterface.get_editor_theme().get_icon("ScriptRemove", "EditorIcons")
		remove_btn.pressed.connect(func (): _remove_row(row))
		row_container.add_child(remove_btn)

		$ContentContainer.add_child(row_container)


func _remove_row(row: ResourceRow) -> void:
	var i = rows.find(row)
	rows.remove_at(i)
	print("Removing %s" % row.orig_path)
	DirAccess.remove_absolute(row.orig_path)
	EditorInterface.get_resource_filesystem().scan()
	_update_content()


func add_column(container: Node, name: String, value: String, width: int = 240) -> Signal:
	var prop_edit = LineEdit.new()
	prop_edit.placeholder_text = name
	prop_edit.text = value
	prop_edit.custom_minimum_size.x = width
	container.add_child(prop_edit)
	return prop_edit.text_changed


func _on_add_item_button_pressed() -> void:
	var row = ResourceRow.new()
	row.resource = table.child_type.new()
	row.id = ""
	rows.append(row)
	_update_content()


func _on_prefix_edit_text_changed(new_text: String) -> void:
	table.prefix = new_text


class ResourceRow:
	extends RefCounted

	var id: String

	var resource: Resource

	var orig_id: String

	var orig_path: String