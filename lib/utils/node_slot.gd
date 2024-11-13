## Helper which allows easier replacing of node on the same path
class_name NodeSlot
extends RefCounted

var _owner: Node
var _slot_name: String
var _parent_path: NodePath

## The last instantiated PackedScene using get_or_instantiate.
var _last_instantiated: PackedScene

var node: Node


func _init(owner: Node, slot_name: String, parent_path: NodePath = NodePath("./")) -> void:
	_owner = owner
	_slot_name = slot_name
	_parent_path = parent_path


## Replace current content of this slot (if any) with given node
func mount(new_node: Node) -> Node:
	clear()
	node = new_node
	node.name = _slot_name
	_owner.get_node(_parent_path).add_child(node)
	return new_node


## Return currently mounted node or mount new instance of given scene
## class if there is none or it's a differernt scene
func get_or_instantiate(nodeclass: PackedScene) -> Node:
	if not node or _last_instantiated != nodeclass:
		_last_instantiated = nodeclass
		mount(nodeclass.instantiate())
	return node


## Return currently mounted node or mount a new instance of given node
## class if there is none or it's a differernt class
func get_or_new(nodeclass: GDScript) -> Node:
	if not node or node.get_script() != nodeclass:
		@warning_ignore("unsafe_call_argument")
		mount(nodeclass.new())
	return node


func clear() -> void:
	if node:
		var parent: Node = node.get_parent()
		parent.remove_child(node)
		node.queue_free()
		node = null


func is_empty() -> bool:
	return not node
