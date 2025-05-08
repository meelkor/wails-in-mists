## Attack of opporitunity basically. Modifier which triggers some combat
## whenever character leaves this character's range.
class_name ModifierAoo
extends Modifier


func on_trigger(character: GameCharacter, trigger: EffectTrigger, _source: ModifierSource) -> void:
	var left := trigger as LeftReachTrigger
	var wpn := character.equipment.get_weapon()
	if left and character == trigger.character and wpn and wpn.get_damage_dice() > 0 and left.leaving_character.enemy != character.enemy:
		# end the movement
		trigger.combat.update_combat_action(left.leaving_character)
		# deal dmg (todo: animation and stuff)
		trigger.combat.deal_damage(left.leaving_character, Dice.roll(wpn.get_damage_dice()).value, character)
