# Controller for a started ability that exists from moment player clicks an
# ability until the ability is finished or cancelled. Serves as communication
# channel between game scenes and the ability logic (selecting targets, running
# animation, affecting game characters...). This is required so abilities with
# custom script may exist where the script gets this instance and it should be
# able to do all those things.
class_name AbilityController
extends Node

var caster: GameCharacter

var ability: Ability

var needs_target: bool = true

var reach: float:
	get:
		return ability.reach

signal done()

### Public ###

func set_target_character(character: GameCharacter) -> void:
	if needs_target: # todo: and needs character target
		pass
		# if can not reach, request movement from parent ctrl


func set_target_point(pos: Vector3) -> void:
	# todo
	pass

func is_abortable() -> bool:
	return needs_target

### Lifecycle ###

func _init() -> void:
	name = "AbilityController"

func _enter_tree() -> void:
	GameCursor.use_select_target()

func _exit_tree() -> void:
	GameCursor.use_default()
