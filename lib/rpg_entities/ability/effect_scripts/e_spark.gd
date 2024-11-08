class_name AbilityEffectSpark
extends AbilityEffect


func execute(req: AbilityRequest) -> void:
	var target_char := req.target.get_character()
	var dc := target_char.get_skill_bonus([Skills.DEFENSE, Skills.FIRE_RESISTANCE])
	var bonus := req.caster.get_skill_bonus([Skills.ACCURACY])
	var roll := Dice.roll(20, bonus)
	global.message_log().system("%s rolled %s againts DC %s" % [req.caster.name, roll.text, dc.get_total()])
	if roll.value >= dc.get_total() or true:
		req.combat.deal_damage(target_char, 10)
