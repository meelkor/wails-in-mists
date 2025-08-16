## A "event payload" that informs buffs, talents and other entities that
## something happened and lets them react to them.
##
## Example: some poison debuff may react on RoundStartedTrigger and deal damage.
##
## Some effect may accept some output from the entity, which can be stored in
## the trigger instance.
##
## Example: AttackOfOpportunityTrigger is emitted before the AOO happens and
## any talen can set some "stopped" flag on the event to true, which makes the
## AOO not happen.
class_name EffectTrigger
extends RefCounted

## Reference to the combat node provided by the combat when emitting the
## trigger, so the handles can e.g. deal damage, check state etc.
var combat: Combat

## Triggers may be either global or character specific (null).
var character: GameCharacter
