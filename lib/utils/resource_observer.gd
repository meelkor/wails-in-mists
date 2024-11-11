## Class which holds list of resources and emitting its own event whenever one
## of the resources is changed
class_name ResourceObserver
extends RefCounted

signal changed()

var _existing: Array[WeakRef] = []


## Update the list of child resources we are listening to
func update(list: Array) -> void:
	for ref in _existing:
		var res: Resource = ref.get_ref()
		if res:
			res.changed.disconnect(_emit_changed)
	_existing = []
	for res: Resource in list:
		res.changed.connect(_emit_changed)
		_existing.append(weakref(res))


func _emit_changed() -> void:
	changed.emit()
