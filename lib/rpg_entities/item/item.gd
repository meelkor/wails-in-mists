extends Slottable
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


## Defines text displayed with the item's name in its descriptive tooltip
func get_heading() -> String:
	return "Garbage"


func _to_string() -> String:
	return "<Item:%s#%s>" % [name, get_instance_id()]
