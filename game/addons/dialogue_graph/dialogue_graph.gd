## Resource representing full dialogue tree with decision / condition branches.
@tool
class_name DialogueGraph
extends Resource

const DialogueBegin := preload("res://addons/dialogue_graph/steps/dialogue_begin.gd")
const DialogueSay := preload("res://addons/dialogue_graph/steps/dialogue_say.gd")

## List of "dialogue steps" where steps may be actions like "Character says",
## "Player decides", "Character moves here or does action" etc. or meta steps
## such as "Begin", "Check state" and so on. When editing the dialogue in
## Editor, each step is then represented by single graph.
##
## Each Dialogue should have exactly one DialogueBegin step.
@export var steps: Array[__DialogueStep]

## Iterator used when creating IDs for new steps to make sure removing and
## adding steps doesn't result in duplicate ID.
@export var iterator: int = 0


## Get step with given ID
func find_step(id: String) -> __DialogueStep:
	var i := find_step_index(id)
	assert(i >= 0, "Could not find step '%s'" % id)
	return steps[i]


## Get index of step with given ID.
##
## todo: consider creating map in case performance becomes an issue
func find_step_index(id: String) -> int:
	return steps.find_custom(func (step: __DialogueStep) -> bool: return step.id == id)


## Remove step with given ID from the dialogue.
func delete_step(id: String) -> void:
	var idx := find_step_index(id)
	if idx >= 0:
		steps.remove_at(idx)
		for step in steps:
			var src_idx := step.source_names.find(id)
			if src_idx >= 0:
				step.source_names.remove_at(src_idx)
				step.source_ports.remove_at(src_idx)
	else:
		push_warning("No dialogue step '%s'" % id)


## Get the Begin step
func get_begin_step() -> __DialogueStep:
	var begin_i := steps.find_custom(func (step: __DialogueStep) -> bool: return step is DialogueBegin)
	if begin_i >= 0:
		return steps[begin_i]
	else:
		push_error("%s: Invalid dialogue - missing begin step" % resource_path)
		return DialogueSay.new()


## Find step with given source step on given its given input port
func find_by_source(source: StringName, port: int) -> __DialogueStep:
	# todo: introduce some index
	for step in steps:
		var idx := step.source_names.find(source)
		if idx == port:
			return step
	return null
