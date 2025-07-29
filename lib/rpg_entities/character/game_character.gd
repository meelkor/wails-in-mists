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

# Emitted after the new action is set. At this point the action is expected to
# be also started by the current controller.
signal action_changed(old_action: CharacterAction, new_action: CharacterAction)


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

@export_file("*.png") var portrait: String = ""

## CharacterAttribute resources mapped to the attribute values
@export var attributes: Dictionary[CharacterAttribute, int] = {}

@export var equipment := CharacterEquipment.new()

@export var visuals: CharacterVisuals

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

## Currently active buffs. Called static because I expect to have buffs
## provided by talents/equipment in the future via modifiers. (buffs will be
## able to provide buffs lmao)
@export var static_buffs: Dictionary[BuffOnset, Buff] = {}

## todo: propbably shouldn't be statically set but instead computed from buffs
## + some allegiance check?
@export var enemy: bool = false:
	get = _is_enemy

@export var sex: CharacterSex = CharacterSex.FEMALE

var pronoun: String = "her":
	get: return "her" if sex == CharacterSex.FEMALE else "his"

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

## Current character's action, which dictates e.g. movement, animation etc.
## This resource only stores current action, the start/end method should be
## handled by this character's controller
##
## When an action is removed (replaced) the action should no longer be
## referenced anywhere and so it gets freed and e.g. subsequent animations are
## not triggered anymore.
var action: CharacterAction = CharacterIdle.new():
	set(a):
		action_changed.emit(action, a)
		action = a
		action.character = self
		emit_changed()

## Currently "active" talent packs.
@export var talents := TalentList.new()

## todo: should be computed from character's state (talents, buffs etc.)
var free_movement_speed := 2.8
## todo: should be computed from character's steps per netrual action (a lot of
## steps = walks fast)
var combat_movement_speed := 1.1

## Once we render portrait in some node, store it here so we can easily access
## it
var cached_portrait: Texture

## WeaponType => int representing proficiency level, 0 being no
## proficiency, 3 being max proficiency.
var _proficiencies: Array[__CombatCategory] = []

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
		for modifier in talent.modifiers:
			modifier.add_skill_bonus(self, bonus, talent.to_source())
	for buff: Buff in static_buffs.values():
		for modifier in buff.modifiers:
			modifier.add_skill_bonus(self, bonus, buff.to_source())
	for item in equipment.get_all():
		var equip := item as ItemEquipment
		if equip:
			for modifier in equip.modifiers:
				modifier.add_skill_bonus(self, bonus, equip.to_source())
	return bonus


func get_attribute(attr: CharacterAttribute) -> int:
	return attributes.get(attr, 0)


func set_attribute(attr: CharacterAttribute, value: int) -> void:
	attributes[attr] = value
	emit_changed()


func add_buff(buff: Buff, onset: BuffOnset = BuffOnset.new()) -> void:
	static_buffs.set(onset, buff)
	emit_changed()


func get_proficiency(type: WeaponType) -> int:
	var l1 := int(type.family.style in _proficiencies)
	var l2 := int(type.family in _proficiencies)
	var l3 := int(type in _proficiencies)
	return l1 + l1 * l2 + l1 * l2 * l3


func get_talent_slot_count() -> int:
	return 1 + level * 2


## Color that should be used for e.g. selection circle to differentiate npcs,
## enemies and party members
func get_color() -> Color:
	return Color.BLACK


## Get all active buffs (both static and possibly computed somehow)
func get_buffs() -> Dictionary[BuffOnset, Buff]:
	# todo: character portrait expects the reference to change so it can
	# compare whether it changed... probably not ideal, reconsider.
	return static_buffs.duplicate()


func get_controller() -> CharacterController:
	return _controller


## Get list of buffs with the injury end trigger.
func get_injuries() -> Array[Buff]:
	var buffs := static_buffs.values()
	var out: Array[Buff] = Array(buffs.filter(func (b: Buff) -> bool: return b.is_injury()))
	return out


## Pass given EffectTigger to all modifiers this character got from various
## sources such as talents or buffs.
func emit_trigger(trigger: EffectTrigger) -> void:
	for equip in equipment.get_all_equipment():
		for modifier in equip.modifiers:
			@warning_ignore("redundant_await")
			await modifier.on_trigger(self, trigger, equip.to_source())
	for talent in talents.get_all_talents():
		for modifier in talent.modifiers:
			@warning_ignore("redundant_await")
			await modifier.on_trigger(self, trigger, talent.to_source())
	for buff: Buff in static_buffs.values():
		for modifier in buff.modifiers:
			@warning_ignore("redundant_await")
			await modifier.on_trigger(self, trigger, buff.to_source())


## Get current reach for AoO trigger if any
func get_aoo_reach() -> float:
	var wpn := equipment.get_weapon()
	if wpn:
		# todo: decide wheter reach should be really on wpn or the AoO modifier
		# instead (probably option b is correct)
		return wpn.ref().reach
	return 0


## Get portrait texture. Can be overriden for NPCs to somehow automatically
## generate when portrait path is not defined.
func get_portrait_texture() -> Texture2D:
	if portrait:
		return load(portrait)
	else:
		return load("res://resources/portraits/placeholder.png")


## Check whether some of the active modifiers has given flag
func has_modifier_flag(flag: StringName) -> bool:
	var yes := false
	for equip in equipment.get_all_equipment():
		for modifier in equip.modifiers:
			yes = yes || modifier.has_flag(flag)
	for talent in talents.get_all_talents():
		for modifier in talent.modifiers:
			yes = yes || modifier.has_flag(flag)
	for buff: Buff in static_buffs.values():
		for modifier in buff.modifiers:
			yes = yes || modifier.has_flag(flag)
	return yes


## Since ability's reach may be modified by talents and wielded weapon, it
## cannot be provided by ability directly and needs to be calculated here by
## character instead
func calculate_reach(ability: Ability) -> float:
	if ability.reach_method == Ability.ReachMethod.STATIC:
		return ability.reach
	elif ability.reach_method == Ability.ReachMethod.BASE_BONUS:
		var wpn_ref := equipment.get_weapon()
		if wpn_ref:
			return ability.reach + wpn_ref.ref().reach
		else:
			push_warning("Calculating ReachMethod.BASE_BONUS ability reach without weapon equipped")
	return 0


## Run all the update methods which recompute values such as proficiency,
## abilities etc. which are based on talents, equipment, attributes etc.
func _update() -> void:
	_update_proficiencies()
	_update_abilities()


## Recompute list of all abilities granted by items and talents
func _update_abilities() -> void:
	var list := [] as Array[Slottable]
	for equip in equipment.get_all_equipment():
		_append_abilities(equip.modifiers, equip.to_source(), list)
	for talent in talents.get_all_talents():
		_append_abilities(talent.modifiers, talent.to_source(), list)
	for buff: Buff in static_buffs.values():
		_append_abilities(buff.modifiers, buff.to_source(), list)
	abilities.set_entities(list as Array[Slottable])


func _append_abilities(modifiers: Array[Modifier], source: ModifierSource, list: Array[Slottable]) -> void:
	for modifier in modifiers:
		for grant in modifier.get_abilities(self, source):
			if grant.available:
				list.append(grant.ability)


## Recompute proficiency dictionary from character's modifiers.
##
## todo: I hate how I need to repeat the same code because gdscript has no
## traits or something that would allow me to work with all classes with
## .modifiers property the same...
func _update_proficiencies() -> void:
	var categories: Dictionary[__CombatCategory, bool]
	for equip in equipment.get_all_equipment():
		for modifier in equip.modifiers:
			for ref in modifier.get_proficiencies(self, equip.to_source()):
				categories[ref] = true
	for talent in talents.get_all_talents():
		for modifier in talent.modifiers:
			for ref in modifier.get_proficiencies(self, talent.to_source()):
				categories[ref] = true
	for buff: Buff in static_buffs.values():
		for modifier in buff.modifiers:
			for ref in modifier.get_proficiencies(self, buff.to_source()):
				categories[ref] = true
	_proficiencies = categories.keys()


func _is_enemy() -> bool:
	return enemy


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

enum CharacterSex {
	FEMALE,
	MALE,
}
