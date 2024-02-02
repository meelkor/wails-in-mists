# Defines visual appearance of something that the ability spawns for short
# moment and the animation during the "casting" (e.g. magic casting, weapon
# slash...)
#
# This class shouldn't handle long lasting effects of buffs or the effect
# caused on target character. That should be handled by the AbilityEffect
# class.
class_name AbilityVisuals
extends Resource

func execute(_ctrl: CharacterController, _ability: Ability, _target: AbilityTarget) -> Execution:
	assert(false, "AbilityVisuals#execute not implemented")
	return Execution.new()

# Execution process informing about the current phase of the visuals animation
class Execution:
	extends RefCounted

	# Signal emitted once the projectile reaches is target and starts the final
	# phase. Usually we want to resolve the game effects at this point
	signal hit()

	# Signal emitted once the visual effect ends completely
	signal completed()
