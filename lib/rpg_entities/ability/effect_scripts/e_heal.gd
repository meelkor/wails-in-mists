class_name AbilityEffectHeal
extends AbilityEffect

@export var amount: int = 0


func execute(req: AbilityRequest) -> void:
	for character in req.resolved_targets:
		req.combat.heal_character(character, amount, req.caster)
