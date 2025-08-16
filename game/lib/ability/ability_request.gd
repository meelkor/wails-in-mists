## Controller for a started ability that exists from moment player clicks an
## ability until the ability is finished or cancelled. Serves as communication
## channel between game scenes and the ability logic (selecting targets, running
## animation, affecting game characters...). This is required so abilities with
## custom script may exist where the script gets this instance and it should be
## able to do all those things.
class_name AbilityRequest
extends RefCounted

const TargetFilter = Ability.TargetFilter

var caster: GameCharacter

var ability: Ability

var target: AbilityTarget

var combat: Combat

## Last movement action assigned to the caster which is trying to reach the
## ability's target
var movement_action: CharacterAction

## List of all characters in area of effect (if applicable) that is resolved
## the moment the skill actually hits. Set by AbilityResolver before the
## ability effect is actually executed. For self/single only selected character
## is included.
var resolved_targets: Array[GameCharacter]


## Check whether caster can reach currently assigned target
##
## todo: check vision using raycasting I guess
func can_reach() -> bool:
	var w_pos := target.get_world_position(false)
	var none := target.is_none()
	return none or caster.position.distance_to(w_pos) - target.buffer_radius <= caster.calculate_reach(ability)


func move_to_target() -> void:
	var desired_pos := target.get_world_position(false)
	var movement := caster.action as CharacterExplorationMovement
	if not movement or not movement.desired_goal.is_equal_approx(desired_pos):
		movement_action = CharacterExplorationMovement.new(desired_pos)
		caster.action = movement_action


## Check whether given character is targetable by the casted ability
func is_targetable(character: GameCharacter) -> bool:
	var opposite := character.enemy != caster.enemy
	var filter := ability.target_filter
	return filter == TargetFilter.ALL\
		or opposite and filter == TargetFilter.ENEMY\
		or not opposite and filter == TargetFilter.FRIENDLY
