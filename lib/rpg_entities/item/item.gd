extends Slottable
class_name Item

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
}

@export var name: String:
	get = _make_name

@export var description: String

@export var flavor_text: String

@export var rarity: Rarity


## Defines text displayed with the item's name in its descriptive tooltip
func get_heading() -> String:
	return "Garbage"


## Name getter so subclasses can implement their automatic name generation
func _make_name() -> String:
	return name


func _to_string() -> String:
	return "<Item:%s#%s>" % [name, get_instance_id()]
