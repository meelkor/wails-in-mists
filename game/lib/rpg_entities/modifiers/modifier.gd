## Defines behaviour in which way the modified entity affects character
## (positive or negative). Modifiers are expected to be used with equipment,
## talents and buffs.
class_name Modifier
extends Resource


## Optional method which may be implemented by the modifier
func add_skill_bonus(_character: GameCharacter, _skill_bonus: SkillBonus, _source: ModifierSource) -> void:
	pass


## Optional method to grant abilities to character which may be implemented by
## the modifier
func get_abilities(_character: GameCharacter, _source: ModifierSource) -> Array[AbilityGrant]:
	return []


## Grant weapon proficiencies of certain level for a weapon type. Realistically
## will only be used by talents.
func get_proficiencies(_character: GameCharacter, _source: ModifierSource) -> Array[__CombatCategory]:
	return []


## Can be overriden by subclass to react to specific combat effect triggers
## such as CombatStartedTrigger
func on_trigger(_character: GameCharacter, _trigger: EffectTrigger, _source: ModifierSource) -> void:
	pass


## Optional method which may be implemented by the modifier. Sometimes the
## owning entity (talent, buff whatever) may use its own description.
func get_label() -> String:
	return ""


## todo: figure out how to define interactive text with hyperlinks to stats etc
func get_description() -> String:
	return ""


## Check whether this modifier represents some of "well known flags" such as
## "aoo". Used to deduplicate some modifiers (so no chara can have more than
## one aoo effect) or to change visual representation of sth in game (red
## navigation thing when passing enemy w/ aoo)
##
## dumb, dumb, I hate it, the aoo abstraction into modifier was bad idea, but
## let's go
func has_flag(_flag: StringName) -> bool:
	return false


## Create a tooltip content block which describes the modifier's effect in
## detail, including all necessary hypertext links etc.
##
## todo: just a test replacement for the static description, dunno how to
## handle this yet
func make_tooltip_blocks() -> Array[RichTooltip.TooltipBlock]:
	return [RichTooltip.StyledLabel.new(get_description())]
