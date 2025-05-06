## General class that should be used as base for each dialogue node scene
## script or can be used as it is if the step doesn't require any
## configuration.
@tool
class_name DialogueNode
extends GraphNode

@export var dialogue: DialogueGraph

@export var step_id: StringName


## Ideally the node would store reference to the node but that doesn't work
## until I solve this nonsense. https://forum.godotengine.org/t/-/101266
func get_step() -> __DialogueStep:
	return dialogue.find_step(step_id)
