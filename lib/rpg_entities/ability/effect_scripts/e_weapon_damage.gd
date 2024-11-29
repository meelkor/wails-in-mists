## Deal damage based on currently equiped weapon with some optional
## ability-based bonuses.
class_name AbilityEffectWeaponDamage
extends AbilityEffect

## Bonus to the attack skill the skill adds
@export var attack_bonus: int = 0

## Minimum damage on hit
@export var damage_bonus: int = 0


func execute(req: AbilityRequest) -> void:
	var target_char := req.target.get_character()
	# todo: add support for multiple damage rolls (e.g. steel d6 + fire d6)
	# where each roll has its own bonuses and the defender has extra bonuses to
	# the defense (resistence and attack type-specific DR)
	var dc := target_char.get_skill_bonus([Skills.DEFENSE])
	var bonus := req.caster.get_skill_bonus([Skills.ATTACK])
	var used_wpn := req.caster.equipment.get_weapon()
	bonus.add(Skills.ATTACK, used_wpn.item.name, used_wpn.bonus)
	var roll := Dice.roll(20, bonus)
	global.message_log().system("%s rolled %s againts DC %s" % [req.caster.name, roll.text, dc.get_total()])
	if roll.value >= dc.get_total() or true:
		req.combat.deal_damage(target_char, 10, req.caster)
