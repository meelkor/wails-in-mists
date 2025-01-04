class_name AbilityEffectGrantBuff
extends AbilityEffect

@export var buff: Buff


func execute(req: AbilityRequest) -> void:
	for character in req.resolved_targets:
		req.combat.grant_buff(character, buff)
