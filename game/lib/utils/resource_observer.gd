## Class which holds list of resources and emitting its own event whenever one
## of the resources is changed. Optionally different signal than "changed" can
## be used.
class_name ResourceObserver
extends RefCounted

signal changed()

var _existing: Array[WeakRef] = []

var signal_name: String


func _init(sn: StringName = &"changed") -> void:
	signal_name = sn


## Update the list of child resources we are listening to
func update(list: Array) -> void:
	for ref in _existing:
		var res: Resource = ref.get_ref()
		if res:
			res.disconnect(signal_name, _emit_changed)
	_existing = []
	for res: Resource in list:
		res.connect(signal_name, _emit_changed)
		_existing.append(weakref(res))


func _emit_changed(_a: Variant = null, _b: Variant = null) -> void:
	changed.emit()
