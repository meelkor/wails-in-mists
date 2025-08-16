## Execution process informing about the current phase of the ability casting
## and visuals animation, since we may want to compute the ability result
## before the animation ends.
##
## Tbh the correct way to do this is that the projectile or the ability visual
## effect should somehow collide with the target and that start the ability
## effect but I am already commited to doing everything wrong.
##
## tbh I'll probably need to change it as described ^ since effects of
## abilities like firewall need to be handle completely separetely from the
## "casting" logic...
class_name AbilityExecution
extends RefCounted

## Signal emitted once the projectile reaches is target and starts the final
## phase. Usually we want to resolve the game effects at this point.
signal hit()

## Signal emitted once the visual effect ends completely.
signal completed()
