## Step used as entrypoint in the dialogue graph
@tool
extends __DialogueStep

## Whether the game should switch to "cutscene" mode where player cannot
## control it, while the dialogue is going.
@export var blocking: bool:
	set(v):
		blocking = v
		emit_changed()

## When true, camera is moved to the interacted character on dialogue start
@export var focus_actor: bool:
	set(v):
		focus_actor = v
		emit_changed()


func execute(ctx: DialogueContext) -> int:
	var gui := ctx.di.inject(LevelGui) as LevelGui
	gui.fade_out_bottom_default()
	if focus_actor:
		var camera := ctx.di.inject(LevelCamera) as LevelCamera
		await camera.ease_to(ctx.actor.get_controller().position)
	return 0


func __make_node() -> DialogueNode:
	return (load("res://addons/dialogue_graph/nodes/node_begin.tscn") as PackedScene).instantiate() as DialogueNode
