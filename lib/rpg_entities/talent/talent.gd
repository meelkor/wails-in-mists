## Abstract class for talents
class_name Talent
extends Resource


## Visible name
func name() -> String:
	return ""


## Visible icon (texture?)
func icon() -> Texture2D:
	return PlaceholderTexture2D.new()


## Method the talent script may implement to grant bonus (possibly negative) to
## skills listed in the bonus instance. The bonus may depend on some
## information about the character and thus has the whole GameCharacter
## instance available.
func add_skill_bonus(_char: GameCharacter, _bonus: SkillBonus) -> void:
	pass


## Called when player tries to equip the talent. Should check whether given
## character has all the requirements.
func allowed(_char: GameCharacter) -> bool:
	return true


## Return list of level + weapon type combination for which this talent grants
## get_proficiency.
func get_proficiencies(_char: GameCharacter) -> Array[ProficiencyTypeRef]:
	return []


## Return abilities granted when this talent is equpped
##
## todo: consider merging with item modifiers
func get_abilities(_char: GameCharacter) -> Array[AbilityGrant]:
	return []


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
