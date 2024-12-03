class_name AbilityEffectSpark
extends AbilityEffect


func execute(req: AbilityRequest) -> void:
	var target_char := req.target.get_character()
	var dc := target_char.get_skill_bonus([Skills.DEFENSE, Skills.FIRE_RESISTANCE])
	var bonus := req.caster.get_skill_bonus([Skills.ACCURACY])
	var roll := Dice.roll(20, bonus)
	# todo: this needs to get generalized, but dunno where... the effect script
	# should just say [roll against this, result is dmg] or [roll against DC,
	# if success result is dmg and debuff, else something]
	global.message_log().system("%s rolled %s againts DC %s" % [req.caster.name, roll.text, dc.get_total()])
	target_char.controller.show_headline_roll(roll, req.ability.name)
	if roll.value >= dc.get_total() or true:
		req.combat.deal_damage(target_char, 10, req.caster)
