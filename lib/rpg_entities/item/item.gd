extends Resource
class_name Item

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
}

@export var name: String

@export var description: String

@export var flavor_text: String

@export var rarity: Rarity

@export var icon: Texture2D


## Defines text displayed with the item's name in its descriptive tooltip
func get_heading() -> String:
	return "Garbage"
