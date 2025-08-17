# Handles the effect of an ability once it "connects" (caster finishes
# casting). Such effects are usually hit rolls, calculating damage and applying
# it to targets, changing state of target characters with (de)buffs etc.
#
# Resolving attacks should be done using handlers that also take care of
# running correct animation on target character.
@abstract
class_name AbilityEffect
extends Resource


## Function which needs to be defined in the subclass
@abstract
func execute(req: AbilityRequest) -> void
