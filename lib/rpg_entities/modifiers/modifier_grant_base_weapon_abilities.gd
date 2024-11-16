# Modifier which grants predefined abilities based on weapon type, since every
# weapon (possibly excluding some unique weapons) should grant basic attacks.
# Number of granted variants of the basic attack is based on character's
# proficiency in the weapon type and the weapon's quality
class_name ModifierGrantBaseWeaponAbilities
extends Modifier


func get_abilities(character: GameCharacter, ref: ItemRef) -> Array[AbilityGrant]:
	# todo: decide how to define the ability sets per weapon type. inb4 I'll
	# make them into resources in the end anyway
	var wpn := ref as WeaponRef
	if wpn:
		var wpn_type := wpn.get_weapon().type
		var proficiency := character.get_proficiency(wpn_type)
		# those most basic abilities do not need to be defined as saved
		# resource since they are never directly referenced by another saved
		# resource
		var basic_attack := Ability.new()
		basic_attack.id = "generated_basic_attack"
		basic_attack.name = "Basic swing"
		basic_attack.visuals = preload("res://lib/rpg_entities/ability/visuals/weapon_swing.gd").new()
		basic_attack.target_type = Ability.TargetType.SINGLE
		basic_attack.icon = preload("res://resources/ability_icons/sword_attack_1.png")
		basic_attack.reach = 1 # todo: base on weapon... weapon property???
		basic_attack.ends_turn = true
		basic_attack.required_actions = [CharacterAttributes.FLESH] # todo: depends on wpn... property of weapon type?
		# todo: how should proficiency even affect the attack?
		var effect := preload("res://lib/rpg_entities/ability/effect_scripts/e_weapon_damage.gd").new()
		basic_attack.effect = effect

		# just a test
		var secondary_attack := Ability.new()
		secondary_attack.id = "generated_secondary_attack"
		secondary_attack.name = "Crippling swing"
		secondary_attack.visuals = preload("res://lib/rpg_entities/ability/visuals/weapon_swing.gd").new()
		secondary_attack.target_type = Ability.TargetType.SINGLE
		secondary_attack.icon = preload("res://resources/ability_icons/sword_attack_1.png")
		secondary_attack.reach = 1 # todo: base on weapon... weapon property???
		secondary_attack.ends_turn = true
		secondary_attack.required_actions = [CharacterAttributes.FLESH, null]

		return [
			AbilityGrant.new(basic_attack, proficiency > 0),
			AbilityGrant.new(secondary_attack, proficiency > 1 and wpn.quality >= WeaponMeta.Quality.REGULAR),
		]
	else:
		push_warning("ModifierGrantBaseWeaponAbilities used on non-weapon ref %s" % ref.item.name)
		return []
