## Little experiemnt for change detection lol
class_name State
extends RefCounted

var _last_value: RefCounted


func changed(new_value: RefCounted) -> bool:
	if _last_value != new_value:
		_last_value = new_value
		return true
	else:
		return false
