class_name ModifierProficiency
extends Modifier

## L1 weapon types to give proficiency for
@export var l1_types: Array[CombatStyle]

## L2 weapon types to give proficiency for
@export var l2_types: Array[WeaponFamily]

## L3 weapon types to give proficiency for
@export var l3_types: Array[WeaponType]

## When true, also gives proficiency for all parent weapon types. (e.g. if this
## talent only lists short sword proficiency, it will also grant one handed
## combat and melee as well)
@export var give_parents: bool = false


func get_proficiencies(_c: GameCharacter, _source: ModifierSource) -> Array[__CombatCategory]:
	var out: Array[__CombatCategory]
	for type in l1_types:
		out.append(type)
	for type in l2_types:
		out.append(type)
		if give_parents:
			out.append(type.style)
	for type in l3_types:
		out.append(type)
		if give_parents:
			out.append(type.family)
			out.append(type.family.style)
	return out


func get_label() -> String:
	var labels: Array[String] = []
	for type in l1_types:
		labels.append(type.name)
	for type in l2_types:
		labels.append(type.name)
	for type in l3_types:
		labels.append(type.name)
	return "%s proficiency" % ", ".join(labels)

