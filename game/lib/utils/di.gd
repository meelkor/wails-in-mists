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

var _registry: Dictionary[Variant, NodePath]

var _parent: DI


func _init(owner: Node, provisions: Dictionary[Variant, NodePath] = {}) -> void:
	_owner = owner
	_registry = provisions
	owner.tree_entered.connect(_find_parent_di)


## Inject instance of given Script or GDScriptNativeClass that is registered
## with this DI or any of its ancestors.
func inject(klass: Variant) -> Node:
	if _registry.has(klass):
		var node_path := _registry[klass]
		var node := _owner.get_node(node_path)
		# For classes that serve just as an interface/trait a __create_proxy
		# method can be implemented which creates instance of the class that is
		# being injected which proxies all calls/signals to the actually
		# provided class. That way the actually provided instance doesn't
		# necessary need to extends the klass class but we can still use it as
		# type when injecting and we won't get "assigning wrong type" runtime
		# error.
		#
		# It's absolutely ridiculous dumbass solution to non-existent problem
		# but it works
		if node.has_method("__create_proxy"):
			@warning_ignore("unsafe_method_access")
			return node.__create_proxy()
		else:
			return node
	else:
		if _parent:
			return _parent.inject(klass)
		else:
			assert(false, "Could not inject class %s" % klass.resource_path)
	return


## Register a new node into existing node instance on runtime. Shouldn't be
## needed except few hacks such as LevelTester which simulates GameInstance.
func register(klass: Variant, instance: Variant) -> void:
	_registry[klass] = instance


func _find_parent_di() -> void:
	var node := _owner.get_parent()
	while node:
		if "di" in node:
			@warning_ignore("unsafe_property_access")
			_parent = node.di
			break
		node = node.get_parent()
