## Abstract class for talents
class_name Talent
extends Resource


## Visible name
func name() -> String:
	return ""


## Visible icon (texture?)
func icon() -> String:
	return ""


## Method the talent script may implement to grant bonus (possibly negative) to
## selected skills. The bonus may depend on some information about the
## character and thus has the whole GameCharacter instance available.
func skill_bonus(_char: GameCharacter, _skill: Skill, _bonus: SkillBonus) -> int:
	return 0


## Called when player tries to equip the talent. Should check whether given
## character has all the requirements.
func allowed(_char: GameCharacter) -> bool:
	return true


## Return list of level + weapon type combination for which this talent grants
## proficiency.
func proficiency(_char: GameCharacter) -> Array[ProficiencyTypeRef]:
	return []


class ProficiencyTypeRef:
	extends RefCounted

	## 1 | 2 | 3
	var level: int
	## WeaponMeta.TypeL3Id | WeaponMeta.TypeL2Id | WeaponMeta.TypeL1Id
	var type: int

	func _init(ilevel: int, itype: int) -> void:
		level = ilevel
		type = itype
