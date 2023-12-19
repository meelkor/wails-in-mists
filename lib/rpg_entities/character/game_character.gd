# Represents any game character be it PC or NPC. Contains all necessary
# variables for combat calculations, visuals and current state in the level
# etc.
class_name GameCharacter
extends Resource

# Signal emitted whenever equipment or starts change
signal state_changed(character: GameCharacter)

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
@export var position: Vector3:
	set(pos):
		position_changed.emit(pos)
		position = pos

@export var attributes: CharacterAttributes = CharacterAttributes.new()

# todo: maybe this shouldn't be here at all but it's so useful when deciding
# behaviour around the character...
var active_combat: Combat

# Scene which contains the character's base model
#
# todo: all those model, skin, hair etc should be encapsulated into some
# "CharacterVisuals" resource
var model: PackedScene = preload("res://models/human_female.tscn")

var skin_color: Color = Color.from_string("E4BCAE", Color.WHITE)

# Resource paht of the mesh (GLB) with the hair
var hair: PackedScene

# Albedo color for the hair mesh. Original model's texture is ignored.
var hair_color: Color

# ItemEquipment.Slot => ItemEquipment
@export var _equipment: Dictionary = {}

# Current character's action, which dictates e.g. movement, animation etc. This
# resource only stores current action, the start/end method should be handled
# by this character's controller
var action: CharacterAction = CharacterIdle.new():
	set(a):
		before_action_changed.emit(a)
		action = a
		action_changed.emit(a)

func get_equipment(slot: int) -> ItemEquipment:
	return _equipment.get(slot)

# Returns previously equipped item. Needs to be put into inventory or
# something, otherwise it will be lost!
func set_equipment(slot: int, item: ItemEquipment) -> ItemEquipment:
	var prev = _equipment.get(slot)
	_equipment[slot] = item
	state_changed.emit(self)
	return prev

# Returns previously equipped item. Needs to be put into inventory or
# something, otherwise it will be lost!
func clear_equipment(slot: int) -> ItemEquipment:
	var prev = _equipment.get(slot)
	_equipment.erase(slot)
	state_changed.emit(self)
	return prev