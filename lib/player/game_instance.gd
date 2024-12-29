## Root node which contains player's "global" (=not level specific) state and
## takes care of switching levels when requested.
class_name GameInstance
extends Node

@export var state: PlayerState
