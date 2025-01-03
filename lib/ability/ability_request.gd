## Controller for a started ability that exists from moment player clicks an
## ability until the ability is finished or cancelled. Serves as communication
## channel between game scenes and the ability logic (selecting targets, running
## animation, affecting game characters...). This is required so abilities with
## custom script may exist where the script gets this instance and it should be
## able to do all those things.
class_name AbilityRequest
extends RefCounted

var caster: GameCharacter

var ability: Ability

var target: AbilityTarget

var combat: Combat

## Last movement action assigned to the caster which is trying to reach the
## ability's target
var movement_action: CharacterAction


## Check whether caster can reach currently assigned target
##
## todo: check vision using raycasting I guess
func can_reach() -> bool:
	# todo: check if needs target, currently won't work for non-targeted skills
	var w_pos := target.get_world_position(false)
	var none := target.is_none()
	return none or caster.position.distance_to(w_pos) <= ability.reach


func move_to_target() -> void:
	var desired_pos := target.get_world_position(false)
	var movement := caster.action as CharacterExplorationMovement
	if not movement or movement.goal != desired_pos:
		movement_action = CharacterExplorationMovement.new(desired_pos)
		caster.action = movement_action
