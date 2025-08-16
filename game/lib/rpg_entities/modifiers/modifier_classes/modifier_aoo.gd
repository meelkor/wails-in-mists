## Attack of opporitunity basically. Modifier which triggers some combat
## whenever character leaves this character's range.
class_name ModifierAoo
extends Modifier

func on_trigger(character: GameCharacter, trigger: EffectTrigger, _source: ModifierSource) -> void:
	var left := trigger as LeftReachTrigger

	if left:
		var wpn := character.equipment.get_weapon()
		if character == trigger.character and wpn and wpn.get_damage_dice() > 0 and left.leaving_character.enemy != character.enemy:

			# todo finalize this experiment. I'll probably need to use the
			# Engine.time_scale after all since physics based things like
			# particle emitters do not care about my scale.
			var test := character.get_controller().create_tween()
			test.set_ease(Tween.EASE_OUT_IN)
			test.tween_property(Engine, "time_scale", 0.3, 0.2)
			test.chain().tween_property(Engine, "time_scale", 1, 1.8)
			var swing := AnimationVisuals.new()
			swing.target_aware = true
			swing.requires_weapon = true
			var exec := AbilityExecution.new()

			var bonus := left.leaving_character.get_skill_bonus([])
			var save_roll := Dice.d20(bonus, 10)
			left.leaving_character.get_controller().show_headline_roll(save_roll, "Disengage")

			swing.execute(exec, character.get_controller(), null, AbilityTarget.from_character(left.leaving_character))

			await exec.hit

			if not save_roll.success:
				trigger.combat.deal_damage(left.leaving_character, Dice.roll(wpn.get_damage_dice()).value, character)

			await exec.completed


func has_flag(flag: StringName) -> bool:
	return flag == &"aoo"
