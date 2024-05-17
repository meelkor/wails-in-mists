# Controller for a started ability that exists from moment player clicks an
# ability until the ability is finished or cancelled. Serves as communication
# channel between game scenes and the ability logic (selecting targets, running
# animation, affecting game characters...). This is required so abilities with
# custom script may exist where the script gets this instance and it should be
# able to do all those things.
class_name AbilityRequest
extends RefCounted

var caster: GameCharacter

var ability: Ability

var target: AbilityTarget

var combat: Combat

### Public ###

func can_reach() -> bool:
	# todo: check if needs target, currently won't work for non-targeted skills
	return caster.position.distance_to(target.get_world_position()) <= ability.reach

func move_to_target():
	var desired_pos = target.get_world_position()
	if not caster.action is CharacterExplorationMovement or caster.action.goal != desired_pos:
		caster.action = CharacterExplorationMovement.new(desired_pos)
