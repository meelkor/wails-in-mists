## Talent which gives proficiency to one or multiple weapon types. Only one of
## the arrays should be used per instance. Types are split per level only so we
## can tell those enums apart..
class_name TalentProficiency
extends Talent

## L1 weapon types to give proficiency for
@export var l1_types: Array[WeaponMeta.TypeL1Id]

## L2 weapon types to give proficiency for
@export var l2_types: Array[WeaponMeta.TypeL2Id]

## L3 weapon types to give proficiency for
@export var l3_types: Array[WeaponMeta.TypeL3Id]

## When true, also gives proficiency for all parent weapon types. (e.g. if this
## talent only lists short sword proficiency, it will also grant one handed
## combat and melee as well)
@export var give_parents: bool = false


## fixme the implementation looks like shit, literally crying rn
##
## todo: deduplication? where to handle?
func get_proficiencies(_c: GameCharacter) -> Array[Talent.ProficiencyTypeRef]:
	var out: Array[Talent.ProficiencyTypeRef]
	if not l1_types.is_empty():
		for type in l1_types:
			out.append(Talent.ProficiencyTypeRef.new(1, type))
	elif not l2_types.is_empty():
		for type in l2_types:
			out.append(Talent.ProficiencyTypeRef.new(2, type))
			if give_parents:
				out.append(Talent.ProficiencyTypeRef.new(1, WeaponMeta.get_l2_type(type).parent.id))
	elif not l3_types.is_empty():
		for type in l3_types:
			out.append(Talent.ProficiencyTypeRef.new(3, type))
			if give_parents:
				var l2 := WeaponMeta.get_l3_type(type).parent.id
				out.append(Talent.ProficiencyTypeRef.new(2, l2))
				out.append(Talent.ProficiencyTypeRef.new(1, WeaponMeta.get_l2_type(l2).parent.id))
	return out
