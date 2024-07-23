# My little dependency injector for easy injecting of nodes provided by the
# parent to the child controllers. E.g. when ability controller needs to access
# terrain controller, level should provide the terrain controller and the
# ability controller should then be able to inject the terrain controller as
# its provided by its parent DI.
#
# I am well aware this is not what Godot was designed around, but I've
# struggled with context switching (e.g. changing what click on terrain does
# depending of game state) for way too long. I am probably doing something
# completely wrong conceptually but hey, trial error here I go~

class_name DI
extends RefCounted

var _owner: Node

var _registry: Dictionary

var _parent: DI

### Lifecycle ###

func _init(owner: Node, provisions: Dictionary = {}):
	_owner = owner
	_registry = provisions
	owner.tree_entered.connect(_find_parent_di)

### Public ###

func inject(klass):
	if _registry.has(klass):
		var path_or_callable = _registry.get(klass)
		if path_or_callable is NodePath:
			return _owner.get_node(path_or_callable)
		elif path_or_callable is Callable:
			return path_or_callable.call()
	else:
		if _parent:
			return _parent.inject(klass)
		else:
			assert(false, "Could not inject class %s" % klass.resource_path)

### Private ###

func _find_parent_di():
	var node = _owner.get_parent()
	while node:
		if "di" in node:
			_parent = node.di
			break
		node = node.get_parent()
