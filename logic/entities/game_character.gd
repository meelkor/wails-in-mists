# Represents any game character be it PC or NPC. Contains all necessary
# variables for combat calculations, visuals and current state in the level
# etc.
class_name GameCharacter
extends Resource

# Signal emitted whenever equipment or starts change
signal state_changed(character: PlayableCharacter)

# Signal emitted whenever position stored in this model changes. Primarily for
# controller to listen to.
signal position_changed(pos: Vector3)

# Emitted before new action is set. When emitted the character still has the
# old action, so it can be compared and whatnot.
signal before_action_changed(new_action: CharacterAction)

# Emitted after the new action is set. At this point the action is expected to
# be also started by the current controller.
signal action_changed(action: CharacterAction)

@export var name: String

# Character's global position on current level. When outside level, it can be
# ignored. When controller exists for that character, the position should be
# synced with it.
var position: Vector3:
	set(pos):
		position_changed.emit(pos)
		position = pos

# Resource path of the scene which contains the character's base model
var model: String = "res://models/human_female.tscn"

var skin_color: Color = Color.from_string("E4BCAE", Color.WHITE)

# Resource paht of the mesh (GLB) with the hair
var hair: String

# Albedo color for the hair mesh. Original model's texture is ignored.
var hair_color: Color

# Equipment.Slot => EquipmentItem
var _equipment: Dictionary = {}

# Current character's action, which dictates e.g. movement, animation etc. This
# resource only stores current action, the start/end method should be handled
# by this character's controller
var action: CharacterAction = CharacterIdle.new():
	set(a):
		before_action_changed.emit(a)
		action = a
		action_changed.emit(a)

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
