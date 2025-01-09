## Structure that should be as key when storing buffs for characters, so we can
## store details about when the buff was gained
class_name BuffOnset
extends Resource

## Combat round on which the buff was granted
@export var starting_round: int = -1
## Turn on which the buff was granted so e.g. when characters grants itself
## defense buff for 1 round at the end of round, it should stay active until the
@export var starting_turn: int = -1


func is_combat() -> bool:
	return starting_round != -1
