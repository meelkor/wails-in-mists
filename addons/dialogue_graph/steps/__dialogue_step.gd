## Abstract class for all steps which then define the whole dialogue /
## interaction tree.
@tool
class_name __DialogueStep
extends Resource

## Name used to reference the node in connections, never displayed ingame
@export var id: String

## List of dialogue steps names which are connected to this step (assumes each
## node has only 1 input)
@export var source_names: Array[String]

## Specifies output port for the sources in source_names. Must always have the
## same size as source_names. (just don't wanna use untyped dicts lol, I so
## want typed tuples)
@export var source_ports: Array[int]

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
