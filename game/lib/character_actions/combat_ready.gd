## Action set for PlayableCharacter that has the turn and is waiting for
## player's input.
class_name CharacterCombatReady
extends CharacterCombatWaiting

func _init() -> void:
	## character is currently static, but we need to have navigation mesh under
	## the character to find exact path character will take, so we can
	## visualize it
	static_obstacle = false
	avoidance_enabled = false
