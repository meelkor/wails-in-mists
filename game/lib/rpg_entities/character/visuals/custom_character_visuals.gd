@tool
## Visuals that simple instantiate given scene without any other alterations.
class_name CustomCharacterVisuals
extends CharacterVisuals

@export var custom_model: PackedScene

var _scene: CharacterScene


func make_scene(_character: GameCharacter, _in_combat: bool) -> CharacterScene:
	if not _scene:
		_scene = custom_model.instantiate()
	return _scene
