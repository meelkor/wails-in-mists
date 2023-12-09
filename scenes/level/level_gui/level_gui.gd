class_name LevelGui
extends Control

var _open_dialog_char:
	set(v):
		_open_dialog_char = v
		_update_portraits()


# Create portraits for given characters and listen for their state change
func set_characters(characters: Array[PlayableCharacter]):
	for character in characters:
		_register_character(character)

# Prepare button for the character's portrait and store ref to the character
func _register_character(character: PlayableCharacter):
	var CharacterPortraitScene = preload("res://scenes/ui/character_portrait/character_portrait.tscn")
	var portrait = CharacterPortraitScene.instantiate()
	portrait.setup(character)
	portrait.right_click.connect(_open_character_dialog)

	$CharactersColumn.add_child(portrait)

# Open character status screen for given character. If there is other
# character's dialog already open it will be closed.
func _open_character_dialog(character: PlayableCharacter):
	if _open_dialog_char == character:
		_clear_existing_dialogs()
	else:
		_clear_existing_dialogs()
		var char_dialog = preload("res://scenes/ui/character_dialog.tscn").instantiate() as CharacterDialog
		char_dialog.setup(character)
		$Dialogs.add_child(char_dialog)
		char_dialog.close.connect(func (): _clear_existing_dialogs())
		_open_dialog_char = character

func _update_portraits():
	for dialog in $CharactersColumn.get_children():
		dialog.announce_dialog_open(_open_dialog_char)

func _clear_existing_dialogs():
	for existing_child in $Dialogs.get_children():
		$Dialogs.remove_child(existing_child)
		existing_child.queue_free()
	_open_dialog_char = null
