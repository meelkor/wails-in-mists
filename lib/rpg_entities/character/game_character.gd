# Represents any game character be it PC or NPC. Contains all necessary
# variables for combat calculations, visuals and current state in the level
# etc.
class_name GameCharacter
extends Resource

var BASE_SKILL_VALUES := {
	Skills.DEFENSE: 10
}

# Signal emitted whenever position stored in this model changes. Primarily for
# controller to listen to.
signal position_changed(pos: Vector3)

# Emitted before new action is set. When emitted the character still has the
# old action, so it can be compared and whatnot.
signal before_action_changed(new_action: CharacterAction)

# Emitted after the new action is set. At this point the action is expected to
# be also started by the current controller.
signal action_changed(action: CharacterAction)

## Signal emitted by combat when character dies, so the controller/owner reacts
## approprietly
signal died_in_combat()

@export var name: String

## Character's global position on current level. When outside level, it can be
## ignored. When controller exists for that character, the position should be
## synced with it.
@export var position: Vector3:
	set(pos):
		position_changed.emit(pos)
		position = pos

## CharacterAttribute resources mapped to the attribute values
@export var attributes: Dictionary = {}

## Scene which contains the character's base model
##
## todo: all those model, skin, hair etc should be encapsulated into some
## "CharacterVisuals" resource
var model := preload("res://models/human_female.tscn") as PackedScene

var skin_color := Color.from_string("E4BCAE", Color.WHITE)

## Resource paht of the mesh (GLB) with the hair
var hair: PackedScene

## Albedo color for the hair mesh. Original model's texture is ignored.
var hair_color: Color

var equipment := CharacterEquipment.new()

## All abilities granted to the character by their talents and items
var abilities := AvailableAbilities.new()

## Current character's action, which dictates e.g. movement, animation etc. This
## resource only stores current action, the start/end method should be handled
## by this character's controller
var action: CharacterAction = CharacterIdle.new():
	set(a):
		before_action_changed.emit(a)
		action = a
		action_changed.emit(a)

var talents: Array[Talent] = []


func _init() -> void:
	equipment.changed.connect(_update_abilities)


## Get instance encapsulating result of bonuses for all given skills
func get_skill_bonus(skills: Array[Skill]) -> SkillBonus:
	var bonus := SkillBonus.new(skills)
	for skill in skills:
		if skill in BASE_SKILL_VALUES:
			bonus.add(skill, "Base %s" % skill.name, BASE_SKILL_VALUES[skill])
	for item in equipment.get_all():
		for modifier in item.modifiers:
			modifier.add_skill_bonus(self, bonus)
	# todo: respect talents
	return bonus


func get_attribute(attr: CharacterAttribute) -> int:
	return attributes.get(attr, 0)


func set_attribute(attr: CharacterAttribute, value: int) -> void:
	attributes[attr] = value
	changed.emit(self)


## Get list of all abilities granted by items and talents
func _update_abilities() -> void:
	var list := [] as Array[Slottable]
	for item in equipment.get_all():
		for modifier in (item as ItemEquipment).modifiers:
			var mga := modifier as ModifierGrantAbility
			if mga:
				list.append(mga.ability)
	abilities.set_entities(list)


func _to_string() -> String:
	return "<GameCharacter:%s#%s>" % [name, get_instance_id()]
