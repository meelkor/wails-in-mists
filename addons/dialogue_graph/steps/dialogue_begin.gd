## Step used as entrypoint in the dialogue graph
@tool
extends __DialogueStep


func execute(ctx: DialogueContext) -> int:
	var gui := ctx.di.inject(LevelGui) as LevelGui
	gui.fade_out_bottom_default()
	return 0


func __make_node() -> DialogueNode:
	return (load("res://addons/dialogue_graph/nodes/node_begin.tscn") as PackedScene).instantiate() as DialogueNode
