# Defines behaviour (usually boon) in which way the modified entity affects
# character. Modifiers are expected to be used with items and skills.
class_name Modifier
extends Resource

@export var id: String

@export var name: String

@export var well_known: bool = false
