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

## Character's level. Available talent slot count and attribute points are
## based of this value.
var level: int = 1

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

## Currently "active" talent packs.
var talents := TalentList.new()

## WeaponMeta.TypeL3Id => int representing proficiency level, 0 being no
## proficiency, 3 being max proficiency.
var _proficiency: Dictionary = {}


func _init() -> void:
	equipment.changed.connect(_update)
	talents.changed.connect(_update)
	_update()


## Get instance encapsulating result of bonuses for all given skills
func get_skill_bonus(skills: Array[Skill]) -> SkillBonus:
	var bonus := SkillBonus.new(skills)
	for skill in skills:
		if skill in BASE_SKILL_VALUES:
			var base_val: int = BASE_SKILL_VALUES.get(skill)
			bonus.add(skill, "Base %s" % skill.name, base_val)
	for talent in talents.get_all_talents():
		talent.add_skill_bonus(self, bonus)
	for item in equipment.get_all():
		var equip := item as ItemEquipment
		if equip:
			for modifier in equip.modifiers:
				modifier.add_skill_bonus(self, bonus)
	return bonus


func get_attribute(attr: CharacterAttribute) -> int:
	return attributes.get(attr, 0)


func set_attribute(attr: CharacterAttribute, value: int) -> void:
	attributes[attr] = value
	emit_changed()


func get_proficiency(type: WeaponMeta.TypeL3Id) -> int:
	return _proficiency.get(type, 0)


func get_talent_slot_count() -> int:
	return 1 + level * 2


## Run all the update methods which recompute values such as proficiency,
## abilities etc. which are based on talents, equipment, attributes etc.
func _update() -> void:
	_update_proficiencies()
	_update_abilities()


## Recompute list of all abilities granted by items and talents
func _update_abilities() -> void:
	var list := [] as Array[Slottable]
	for item in equipment.get_all():
		for modifier in ((item as ItemRef).item as ItemEquipment).modifiers:
			for grant in modifier.get_abilities(self, item as ItemRef):
				if grant.available:
					list.append(grant.ability)
	abilities.set_entities(list)


## Recompute proficiency dictionary from character's talents.
func _update_proficiencies() -> void:
	var tmp: Dictionary
	for talent in talents.get_all_talents():
		for ref in talent.get_proficiencies(self):
			var current: int = tmp.get(ref.type, 0)
			tmp[ref.type] = current | (1 << (ref.level - 1))
	var out: Dictionary
	# temp, the implementation is ridiculous
	for type: WeaponMeta.TypeL3Id in tmp:
		var bitmap: int = tmp.get(type)
		var prof: int = 0
		if bitmap & 1:
			prof += 0b001
			if bitmap & 0b010:
				prof += 1
				if bitmap & 0b100:
					prof += 1
		out[type] = prof
	_proficiency = out


func _to_string() -> String:
	return "<GameCharacter:%s#%s>" % [name, get_instance_id()]
