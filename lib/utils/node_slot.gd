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


## Replace current content of this slot (if any) with given node
func mount(new_node: Node):
	clear()
	node = new_node
	node.name = _slot_name
	_owner.get_node(_parent_path).add_child(node)


## Return currently mounted node or mount new instance of given node class if
## there is none
func get_or_instantiate(nodeclass: PackedScene) -> Node:
	if not node:
		mount(nodeclass.instantiate())
	return node


func clear():
	var parent: Node = _owner.get_node(_parent_path)
	if parent.has_node(_slot_name):
		var current: Node = parent.get_node(_slot_name)
		_owner.remove_child(current)
		current.queue_free()
	node = null
