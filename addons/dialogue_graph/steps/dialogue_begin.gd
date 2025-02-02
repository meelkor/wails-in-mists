## Step used as entrypoint in the dialogue graph
@tool
extends __DialogueStep


func __make_node() -> DialogueNode:
	return (load("res://addons/dialogue_graph/nodes/node_begin.tscn") as PackedScene).instantiate() as DialogueNode
