class_name LevelGui
extends Control

var di = DI.new(self)

@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)

var _current_caster: AbilityCaster

@onready var _ability_caster_bar_slot = NodeSlot.new(self, "AbilityCasterBar", %AbilityCasterBarWrapper.get_path())

signal character_selected(character: PlayableCharacter, type: PlayableCharacter.InteractionType)

### Public ###

# Create portraits for given characters and listen for their state change
func set_characters(characters: Array[PlayableCharacter]):
	for character in characters:
		_register_character(character)


### Lifecycle ###

func _ready():
	_init_message_log()
	_controlled_characters.selected_changed.connect(_update_ability_caster_bar)

### Private ###

# React to character selection changing. Display ability caster when single
# character selected.
func _update_ability_caster_bar(chars: Array[PlayableCharacter]) -> void:
	if chars.size() == 1:
		# todo: consider dropping ability caster and handle everything in the
		# ability caster bar node (including ). not sure why I needed to
		# introduce it
		_current_caster = AbilityCaster.new(chars[0], di.inject(Combat))
		var bar = preload("res://gui/ability_caster_bar/ability_caster_bar.tscn").instantiate()
		bar.caster = _current_caster
		_ability_caster_bar_slot.mount(bar)
	else:
		_current_caster = null
		_ability_caster_bar_slot.clear()

# For which PlayableCharacter the dialog is currently open
var _open_dialog_char:
	set(v):
		_open_dialog_char = v
		_update_portraits()

# Prepare button for the character's portrait and store ref to the character
func _register_character(character: PlayableCharacter):
	var CharacterPortraitScene = preload("res://gui/character_portrait/character_portrait.tscn")
	var portrait = CharacterPortraitScene.instantiate()
	portrait.setup(character)
	portrait.clicked.connect(_on_portrait_click)
	$CharactersColumn.add_child(portrait)

func _on_portrait_click(character: PlayableCharacter, type: PlayableCharacter.InteractionType):
	if type == PlayableCharacter.InteractionType.CONTEXT:
		_open_character_dialog(character)
	else:
		character_selected.emit(character, type)

# Open character status screen for given character. If there is other
# character's dialog already open it will be closed.
func _open_character_dialog(character: PlayableCharacter):
	if _open_dialog_char == character:
		_clear_existing_dialogs()
	else:
		_clear_existing_dialogs()
		var char_dialog = preload("res://gui/character_dialog/character_dialog.tscn").instantiate() as CharacterDialog
		char_dialog.setup(character)
		$Dialogs.add_child(char_dialog)
		char_dialog.close.connect(func (): _clear_existing_dialogs())
		_open_dialog_char = character

# Update portraits according to currently open dialogs
func _update_portraits():
	for dialog in $CharactersColumn.get_children():
		dialog.announce_dialog_open(_open_dialog_char)

# Remove all open char/player dialogs
func _clear_existing_dialogs():
	for existing_child in $Dialogs.get_children():
		$Dialogs.remove_child(existing_child)
		existing_child.queue_free()
	_open_dialog_char = null

# Resize handler of the message log frame
func _on_messages_frame_resize_top(top_offset: float) -> void:
	var frame = (%MessagesFrame as FramedDialog);
	frame.position.y -= top_offset
	frame.size.y += top_offset

# Fill message log with latest messages and listen to new additions
func _init_message_log():
	var msg_log = global.message_log() as MessageLog
	for msg in msg_log.get_latest(10):
		_create_message_label(msg)

	msg_log.message_received.connect(_create_message_label)

func _create_message_label(msg: MessageLogItem):
	var holder = %MessageHolder as VBoxContainer
	var label = RichTextLabel.new()
	var msg_text = msg.text
	if msg.text_color:
		msg_text = "[color=#%s]%s[/color]" % [msg.text_color.to_html(), msg_text]
	if msg.name:
		msg_text = "[color=#%s]%s[/color]: %s" % [msg.name_color.to_html(), msg.name, msg_text]

	label.bbcode_enabled = true
	label.text = msg_text
	label.fit_content = true
	label.scroll_active = false
	holder.add_child(label)
	await get_tree().process_frame
	%MessagesFrame/MarginContainer/ScrollContainer.set_deferred("scroll_vertical", 10000000)
