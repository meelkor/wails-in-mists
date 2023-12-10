# Represents any game character be it PC or NPC. Contains all necessary
# variables for combat calculations etc.
class_name GameCharacter
extends Object

# Signal emitted whenever equipment or starts change
signal state_changed(character: PlayableCharacter)

@export var name: String

# Resource path of the scene which contains the character's base model
var model: String = "res://models/human_female.tscn"

var skin_color: Color = Color.from_string("E4BCAE", Color.WHITE)

# Resource paht of the mesh (GLB) with the hair
var hair: String

# Albedo color for the hair mesh. Original model's texture is ignored.
var hair_color: Color

# Equipment.Slot => EquipmentItem
var _equipment: Dictionary = {}

func _init(new_name: String):
	name = new_name

func get_equipment(slot: int) -> EquipmentItem:
	return _equipment.get(slot)

# Returns previously equipped item. Needs to be put into inventory or
# something, otherwise it will be lost!
func set_equipment(slot: int, item: EquipmentItem) -> EquipmentItem:
	var prev = _equipment.get(slot)
	_equipment[slot] = item
	state_changed.emit(self)
	return prev

# Returns previously equipped item. Needs to be put into inventory or
# something, otherwise it will be lost!
func clear_equipment(slot: int) -> EquipmentItem:
	var prev = _equipment.get(slot)
	_equipment.erase(slot)
	state_changed.emit(self)
	return prev
