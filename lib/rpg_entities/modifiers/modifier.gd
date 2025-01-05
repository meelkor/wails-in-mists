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
func get_proficiencies(_character: GameCharacter, _source: ModifierSource) -> Array[ProficiencyTypeRef]:
	return []


## Optional method which may be implemented by the modifier. Sometimes the
## owning entity (talent, buff whatever) may use its own description.
func get_label() -> String:
	return ""


## todo: figure out how to define interactive text with hyperlinks to stats etc
func get_description() -> String:
	return ""


## Create a tooltip content block which describes the modifier's effect in
## detail, including all necessary hypertext links etc.
##
## todo: just a test replacement for the static description, dunno how to
## handle this yet
func make_tooltip_blocks() -> Array[RichTooltip.TooltipBlock]:
	return [RichTooltip.StyledLabel.new(get_description())]


class ProficiencyTypeRef:
	extends RefCounted

	## 1 | 2 | 3
	var level: int
	## WeaponMeta.TypeL3Id | WeaponMeta.TypeL2Id | WeaponMeta.TypeL1Id
	var type: int
	## Bitmap containing both level and type that can be used to easy identify
	## available proficiencies
	var bitmap: int

	func _init(ilevel: int, itype: int) -> void:
		level = ilevel
		type = itype
		bitmap = itype | (ilevel << 8)
