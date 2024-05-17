extends AbilityEffectScript

static func execute(req: AbilityRequest):
	var target_char = req.target.get_character()
	var dc = target_char.get_skill_bonus([Skill.DEFENSE, Skill.FIRE_RESISTANCE])
	var bonus = req.caster.get_skill_bonus([Skill.ACCURACY])
	var roll = Dice.roll(20, bonus)
	if roll.value >= dc.get_total():
		req.combat.deal_damage(target_char, 1)
	print("guy casts yeah ", req.caster.name)
