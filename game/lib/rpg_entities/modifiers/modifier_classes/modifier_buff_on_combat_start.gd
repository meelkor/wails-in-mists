## Modifier which grants specified buff on combat start.
class_name ModifierBuffOnCombatStart
extends Modifier

@export var buff: Buff

@export var stack: int = 1


func on_trigger(character: GameCharacter, trigger: EffectTrigger, _source: ModifierSource) -> void:
	if trigger is CombatStartedTrigger and character == trigger.character:
		trigger.combat.grant_buff(character, buff, stack)
