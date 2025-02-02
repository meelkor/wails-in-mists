## General class that should be used as base for each dialogue node scene
## script or can be used as it is if the step doesn't require any
## configuration.
@tool
class_name DialogueNode
extends GraphNode

@export var step: __DialogueStep
