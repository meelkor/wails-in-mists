class_name ModifierProficiency
extends Modifier

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
func get_proficiencies(_c: GameCharacter, _source: ModifierSource) -> Array[ProficiencyTypeRef]:
	var out: Array[ProficiencyTypeRef]
	if not l1_types.is_empty():
		for type in l1_types:
			out.append(Modifier.ProficiencyTypeRef.new(1, type))
	elif not l2_types.is_empty():
		for type in l2_types:
			out.append(Modifier.ProficiencyTypeRef.new(2, type))
			if give_parents:
				out.append(Modifier.ProficiencyTypeRef.new(1, WeaponMeta.get_l2_type(type).parent))
	elif not l3_types.is_empty():
		for type in l3_types:
			out.append(Modifier.ProficiencyTypeRef.new(3, type))
			if give_parents:
				var l2 := WeaponMeta.get_l3_type(type).parent
				out.append(Modifier.ProficiencyTypeRef.new(2, l2))
				out.append(Modifier.ProficiencyTypeRef.new(1, WeaponMeta.get_l2_type(l2).parent))
	return out


func get_label() -> String:
	var labels: Array[String] = []
	for type in l1_types:
		labels.append(WeaponMeta._l1_dict[type].name)
	for type in l2_types:
		labels.append(WeaponMeta._l2_dict[type].name)
	for type in l3_types:
		labels.append(WeaponMeta._l3_dict[type].name)
	return "%s proficiency" % ", ".join(labels)

