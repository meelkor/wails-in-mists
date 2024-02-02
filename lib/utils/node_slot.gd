# Helper which allows easier replacing of node on the same path

class_name NodeSlot
extends RefCounted

var _owner: Node
var _slot_name: String
var _parent_path: NodePath

var node: Node

### Lifecycle ###

func _init(owner: Node, slot_name: String, parent_path: NodePath = NodePath("./")):
	_owner = owner
	_slot_name = slot_name
	_parent_path = parent_path

### Public ###

func mount(new_node: Node):
	clear()
	node = new_node
	node.name = _slot_name
	_owner.get_node(_parent_path).add_child(node)

func clear():
	var current: Node = _owner.get_node(_parent_path).get_node(_slot_name)
	if current:
		_owner.remove_child(current)
		current.queue_free()
	node = null
