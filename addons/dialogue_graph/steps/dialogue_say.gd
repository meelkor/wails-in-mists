## Step that writes message in the message log as if character said something
## and waits for for user to hit continue before continuing using its only
## output if the dialogue is blocking
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


func execute(ctx: DialogueContext) -> int:
	var level := ctx.di.inject(BaseLevel) as BaseLevel
	var gui := ctx.di.inject(LevelGui) as LevelGui
	# how long it takes to read this line, todo: temp solution I guess
	var duration := maxf(1.5, text.length() / 12.)
	if level.cutscene_active:
		gui.fade_in_bottom_dialogue()
	var dialogue := ctx.dialogue
	var last := dialogue.find_by_source(id, 0) == null
	if actor == DialogueActor.Target:
		global.message_log().dialogue(ctx.actor.name, ctx.actor.get_color(), text)
	elif actor == DialogueActor.System:
		global.message_log().system(text)
	elif actor == DialogueActor.Custom:
		# todo
		pass
	if level.cutscene_active:
		await global.message_log().prompt(MessageLog.prompt_continue(last))
	else:
		# todo: somehow generalize with the code above, so it's as simple as
		# character.say(words), or more like say(words, character_or_null) or
		# something idk so it works for system
		var chara := custom if custom else ctx.actor
		await chara.get_controller().show_headline_text(text, duration)
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
