## My little dependency injector for easy injecting of nodes provided by the
## parent to the child controllers. E.g. when ability controller needs to
## access terrain controller, level should provide the terrain controller and
## the ability controller should then be able to inject the terrain controller
## as its provided by its parent DI.
##
## I am well aware this is not what Godot was designed around, but I've
## struggled with context switching (e.g. changing what click on terrain does
## depending of game state) for way too long. I am probably doing something
## completely wrong conceptually but hey, trial error here I go~

class_name DI
extends RefCounted

var _owner: Node

var _registry: Dictionary

var _parent: DI


func _init(owner: Node, provisions: Dictionary = {}) -> void:
	_owner = owner
	_registry = provisions
	owner.tree_entered.connect(_find_parent_di)


func inject(klass: Variant) -> Variant:
	if _registry.has(klass):
		var path_or_callable: Variant = _registry.get(klass)
		if path_or_callable is NodePath:
			@warning_ignore("unsafe_call_argument")
			return _owner.get_node(path_or_callable)
		elif path_or_callable is Callable:
			@warning_ignore("unsafe_method_access")
			return path_or_callable.call()
	else:
		if _parent:
			return _parent.inject(klass)
		else:
			assert(false, "Could not inject class %s" % klass.resource_path)
	return


func _find_parent_di() -> void:
	var node := _owner.get_parent()
	while node:
		if "di" in node:
			@warning_ignore("unsafe_property_access")
			_parent = node.di
			break
		node = node.get_parent()
