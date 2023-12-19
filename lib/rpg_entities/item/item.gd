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
