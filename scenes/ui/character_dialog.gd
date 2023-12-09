extends BoxContainer
class_name CharacterDialog

# Signal emitted when the dialog wants to be closed
signal close()

var _character: PlayableCharacter

func setup(character: PlayableCharacter):
	_character = character
	(%CharacterNameLabel as Label).text = character.name

func _input(event: InputEvent) -> void:
	if event.is_action("dialog_close"):
		close.emit()
