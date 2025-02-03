## Abstract class for all steps which then define the whole dialogue /
## interaction tree.
##
## Each connection is defined by value in source_names & source_ports & ports,
## so I do not need to use untyped dict.
@tool
class_name __DialogueStep
extends Resource

## Name used to reference the node in connections, never displayed ingame
@export var id: String

## Specifies source step's name which connects to this step from/to port
## defined by source_ports / port respectively under the same index.
@export var source_names: Array[String]

## Specifies output port for the sources in source_names. Must always have the
## same size as source_names and ports.
@export var source_ports: Array[int]

## Specifies this step's input port which source with the same index is
## connected to
@export var ports: Array[int]

## Position in the graph editor, not used ingame
@export var position: Vector2:
	set(v):
		position = v
		emit_changed()


## Create a node representing this dialogue step.
##
## Should be used only in editor.
func make_node() -> DialogueNode:
	var node := __make_node()
	node.name = id
	node.step = self
	node.position_offset = position
	return node


## Should be implemented by subclass to create a graph node representing this
## step that lets user to update the step.
func __make_node() -> DialogueNode:
	return DialogueNode.new()
