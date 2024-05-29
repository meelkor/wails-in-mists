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

## CharacterAttribute resources mapped to the attribute values
@export var attributes: Dictionary = {}

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
var equipment: EquipmentDict = EquipmentDict.new()

# Current character's action, which dictates e.g. movement, animation etc. This
# resource only stores current action, the start/end method should be handled
# by this character's controller
var action: CharacterAction = CharacterIdle.new():
	set(a):
		before_action_changed.emit(a)
		action = a
		action_changed.emit(a)

# TODO: Should be stored in some talent tree structure
var talents: Array[Talent] = []

# Get instance encapsulating result of bonuses for all given skills
func get_skill_bonus(skills: Array[Skill]) -> SkillBonus:
	var bonus = SkillBonus.new(skills)
	# TODO: come up with how method to define skill logic
	for skill in skills:
		if skill == Skills.DEFENSE:
			if equipment.armor:
				bonus.add(skill, equipment.armor.name, equipment.armor.base_defense_bonus)
		elif skill == Skills.FIRE_RESISTANCE:
			bonus.add(skill, "Inherent lol", 1)
		elif skill == Skills.INITIATIVE:
			bonus.add(skill, "Finesse", get_attribute(CharacterAttributes.FLESH))
	return bonus

func get_attribute(attr: CharacterAttribute) -> int:
	return attributes.get(attr, 0)
