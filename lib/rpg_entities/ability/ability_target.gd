# Class which encapsulates the various possible values for "ability target", so
# we can properly type parameters, which accept those instead of
# position_or_character_or_null.
#
# Should never be constructed by others than the static methods.
class_name AbilityTarget
extends RefCounted

static func from_position(vector: Vector3) -> AbilityTarget:
	var target = AbilityTarget.new()
	target._position = vector
	return target

static func from_character(input_char: GameCharacter) -> AbilityTarget:
	var target = AbilityTarget.new()
	target._character = input_char
	return target

static func from_none() -> AbilityTarget:
	var target = AbilityTarget.new()
	target._none = true
	return target

# possibly null
var _position: Vector3

# possibly null
var _character: GameCharacter

var _none: bool = false

# Assert this target was terrain and get target position
func get_position() -> Vector3:
	assert(_position != null, "Ability target is not position-based")
	return _position

# Assert this target was character and return it
func get_character() -> GameCharacter:
	assert(_position != null, "Ability target is not character-based")
	return _character

# Get world position of the selected character or position
func get_world_position() -> Vector3:
	if _position:
		return _position
	if _character:
		return _character.position
	return Vector3.ZERO

func assert_none():
	assert(_none == true, "Ability target is not empty")
