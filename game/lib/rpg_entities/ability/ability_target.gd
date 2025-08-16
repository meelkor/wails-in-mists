## Class which encapsulates the various possible values for "ability target", so
## we can properly type parameters, which accept those instead of
## position_or_character_or_null.
##
## Should never be constructed by others than the static methods.
class_name AbilityTarget
extends RefCounted


static func from_position(vector: Vector3) -> AbilityTarget:
	var target := AbilityTarget.new()
	target._position = vector
	return target


static func from_character(input_char: GameCharacter) -> AbilityTarget:
	var target := AbilityTarget.new()
	target._character = input_char
	return target


static func from_none() -> AbilityTarget:
	var target := AbilityTarget.new()
	target._none = true
	return target


## possibly ZERO
var _position: Vector3

## possibly null
var _character: GameCharacter

var _none: bool = false


## Buffer in case target is character since we do not need to reach the
## character's center, we just need to touch it.
var buffer_radius: float:
	get:
		return _character.model_radius - 0.2 if _character else 0.


## Assert this target was terrain and get target position
func get_position() -> Vector3:
	assert(_position != Vector3.ZERO, "Ability target is not position-based")
	return _position


## Assert this target was character and return it
func get_character() -> GameCharacter:
	assert(_character != null, "Ability target is not character-based")
	return _character


## Get world position of the selected character or position. If offset is true,
## offset in Y axis is added for purposes of abilities etc.
func get_world_position(offset: bool) -> Vector3:
	if _position:
		return _position
	if _character:
		if offset:
			return _character.get_controller().character_scene.body.get_aabb().get_center() + _character.position
		else:
			return _character.position
	return Vector3.ZERO


func is_none() -> bool:
	return _none


func is_character() -> bool:
	return !!_character


func assert_none() -> void:
	assert(_none == true, "Ability target is not empty")
