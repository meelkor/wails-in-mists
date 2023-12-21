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

signal _target_received()

### Public ###

func target_received() -> void:
	if needs_target():
		await _target_received

func needs_target() -> bool:
	return true

func set_target_character(_character: GameCharacter) -> void:
	_target_received.emit()

func set_target_point(_vec: Vector3) -> void:
	_target_received.emit()

### Lifecycle ###

func _init() -> void:
	name = "AbilityController"
