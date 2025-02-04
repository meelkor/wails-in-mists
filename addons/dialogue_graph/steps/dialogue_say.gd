## Step that writes message in the message log as if character said something
## and waits for for user to hit continue before continuing using its only
## output.
@tool
extends __DialogueStep

## Who is speaking, see DialogueActor
@export var actor: DialogueActor = DialogueActor.Target:
	set(v):
		actor = v
		emit_changed()

## In case actor is "custom" a reference to the character that's talking.
@export var custom: GameCharacter:
	set(v):
		custom = v
		emit_changed()

## Said text
@export var text: String:
	set(v):
		text = v
		emit_changed()


func execute(dialogue: DialogueGraph, dialogue_actor: GameCharacter) -> int:
	var last := dialogue.find_by_source(id, 0) == null
	if actor == DialogueActor.Target:
		global.message_log().dialogue(dialogue_actor.name, dialogue_actor.get_color(), text)
	elif actor == DialogueActor.System:
		global.message_log().system(text)
	elif actor == DialogueActor.Custom:
		# todo
		pass
	await global.message_log().prompt(MessageLog.prompt_continue(last))
	return 0


func __make_node() -> DialogueNode:
	var node := (load("res://addons/dialogue_graph/nodes/node_say.tscn") as PackedScene).instantiate() as DialogueNode
	node.step = self
	return node


enum DialogueActor {
	## When dialogue is started a single character is named an "Target Actor"
	## so we don't need to specify the character for each Say step and can
	## create generic Dialogues that may be used for various characters.
	Target,
	## Narrator, used to describe who does what, what you see etc.
	System,
	## If set, the `custom` property is used. Mostly meant for cases where
	## third party talks in the dialogue.
	Custom,
}
