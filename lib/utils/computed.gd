## Little experiemnt for change detection lol
class_name Computed
extends RefCounted

var _last_values: Dictionary = {}


func changed(name: String, new_value) -> bool:
	if _last_values.get(name, null) != new_value:
		_last_values[name] = new_value
		return true
	else:
		return false
