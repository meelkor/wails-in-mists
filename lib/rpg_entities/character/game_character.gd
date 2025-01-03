# Represents any game character be it PC or NPC. Contains all necessary
# variables for combat calculations, visuals and current state in the level
# etc.
class_name GameCharacter
extends Resource

## Currently hovered character so we don't need to iterate over all characters
## to find the hovered one and with less overhead than using signals, when we
## need this value on every frame for projections.
static var hovered_character: GameCharacter

static var hovered_changed := StaticSignal.make()

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
signal action_changed()

## Signal emitted by combat when character dies, so the controller/owner reacts
## approprietly. Expects killer's position as param.
signal died_in_combat(source: Vector3)

## Emitted when the character is clicked which may come from different sources
## such as portrait, world map, combat participant portrait... So we do not
## need to listen to those various sources, single singal is introduced here.
signal clicked(type: InteractionType)

@export var name: String

## Character's global position on current level. When outside level, it can be
## ignored. When controller exists for that character, the position should be
## synced with it.
@export var position: Vector3:
	set(pos):
		position_changed.emit(pos)
		position = pos

## CharacterAttribute resources mapped to the attribute values
@export var attributes: Dictionary[CharacterAttribute, int] = {}

## Scene which contains the character's base model
##
## todo: all those model, skin, hair etc should be encapsulated into some
## "CharacterVisuals" resource
var model := preload("res://models/human_female.tscn") as PackedScene

var skin_color := Color.from_string("E4BCAE", Color.WHITE)

## Resource paht of the mesh (GLB) with the hair
@export var hair: PackedScene

## Albedo color for the hair mesh. Original model's texture is ignored.
@export var hair_color: Color

@export var equipment := CharacterEquipment.new()

## Character's level. Available talent slot count and attribute points are
## based of this value.
@export var level: int = 1:
	set(v):
		if level != v:
			level = v
			emit_changed()

## Spawns character in dead pose when not true and also disables some
## interactions.
@export var alive: bool = true:
	set(v):
		if alive != v:
			alive = v
			emit_changed()

## Radius for character's selection circle
##
## todo: should not be stored but somehow calculated from character's size...
## maybe from collider's aabb + buffer?
var model_radius: float = 0.345

## All abilities granted to the character by their talents and items
var abilities := AvailableAbilities.new()

## Controller node which currently represents the game. May be null when not in
## overworld.
var _controller: CharacterController

## Current character's action, which dictates e.g. movement, animation etc. This
## resource only stores current action, the start/end method should be handled
## by this character's controller
##
## When an action is removed (replaced) the action should no longer be referenced anywhere and so it gets freed and e.g. subsequent animations are not triggered anymore.
var action: CharacterAction = CharacterIdle.new():
	set(a):
		before_action_changed.emit(a)
		action = a
		emit_changed()
		action_changed.emit()

## Currently "active" talent packs.
@export var talents := TalentList.new()

## todo: should be computed from character's state (talents, buffs etc.)
var free_movement_speed := 2.8
## todo: should be computed from character's steps per netrual action (a lot of
## steps = walks fast)
var combat_movement_speed := 1.1

## WeaponMeta.TypeL3Id => int representing proficiency level, 0 being no
## proficiency, 3 being max proficiency.
var _proficiency: Dictionary[WeaponMeta.TypeL3Id, int] = {}

## Whether the character is hovered in either world or UI (portraits)
##
## TODO: every hover results in all dialogs, caster bar etc. to rerender
## because the resource changes, move into separate signal if the performance
## hit on hover becomes notable
var hovered: bool = false:
	set(v):
		if hovered != v:
			hovered = v
			if hovered:
				GameCharacter.hovered_character = self
			else:
				GameCharacter.hovered_character = null
			GameCharacter.hovered_changed.emit()
			emit_changed()


func _init() -> void:
	equipment.changed.connect(_update)
	talents.changed.connect(_update)
	_update()


## Check whether is not in process of doing something uninteruptable and can
## accept player's commands. For PCs that means the character can be
## controlled. For NPC that player can interact with them.
func is_free() -> bool:
	return action.is_free()


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


## Color that should be used for e.g. selection circle to differentiate npcs,
## enemies and party members
func get_color() -> Color:
	return Color.BLACK


func get_controller() -> CharacterController:
	return _controller


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
	for pack: TalentPack in talents.get_all():
		for talent: Talent in pack.talents:
			for grant in talent.get_abilities(self):
				if grant.available:
					list.append(grant.ability)
	abilities.set_entities(list)


## Recompute proficiency dictionary from character's talents.
func _update_proficiencies() -> void:
	var tmp: Dictionary[WeaponMeta.TypeL3Id, int]
	for talent in talents.get_all_talents():
		for ref in talent.get_proficiencies(self):
			var current: int = tmp.get(ref.type, 0)
			tmp[ref.type] = current | (1 << (ref.level - 1))
	var out: Dictionary[WeaponMeta.TypeL3Id, int]
	for type: WeaponMeta.TypeL3Id in tmp:
		var bitmap: int = tmp.get(type)
		var prof: int = (bitmap & 0b1) + int(bitmap & 0b11 == 0b11) + int(bitmap & 0b111 == 0b111)
		out[type] = prof
	_proficiency = out


func _to_string() -> String:
	return "<GameCharacter:%s#%s>" % [name, get_instance_id()]


enum InteractionType {
	## Select this single character. e.g. left click on portrait
	SELECT,
	## Select this character adding it to the currently selected. e.g.
	## shift+left click on portrait
	SELECT_MULTI,
	# Open information about the character. e.g. right click on portrait
	INSPECT,
}
