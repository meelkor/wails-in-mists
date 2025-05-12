## Emitted to every participant when combat starts or when they join midcombat.
class_name CombatStartedTrigger
extends EffectTrigger


func _to_string() -> String:
	return "<CombatStartedTrigger#%s>" % get_instance_id()
