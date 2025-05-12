## Trigger emitted when any character (friendly or not) leaves another
## character's reach area which (IS IT???) is defined by wielded weapon.
##
## Mostly intended for effects like attack of opportunity
class_name LeftReachTrigger
extends EffectTrigger

## Character that is leaving the reaching character's reach range. In case of
## AoO it is the attacked character. Theoritically always the active character
## in combat.
var leaving_character: GameCharacter


func _to_string() -> String:
	return "<LeftReachTrigger#%s>" % get_instance_id()
