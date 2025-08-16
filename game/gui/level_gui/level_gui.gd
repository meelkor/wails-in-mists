## Contains all the GUI when in overworld level. Can be injected by any part of
## the level scene to open new gui element such as loot dialogs.
class_name LevelGui
extends Control

const LootDialog = preload("res://gui/loot_dialog/loot_dialog.gd")

var di := DI.new(self)

@onready var _base_level := di.inject(BaseLevel) as BaseLevel

## Currently open loot dialogs so we can easily close the correct one when
## requested. (although for now I'll be supporting single loot dialog open lol)
var _open_loot_dialogs: Dictionary[Lootable, WeakRef] = {}

@onready var _ability_caster_bar_slot := NodeSlot.new(self, "AbilityCasterBar", %AbilityCasterBarWrapper.get_path())
@onready var _player_inventor_slot := NodeSlot.new(self, "PlayerInventory", %GuiRight.get_path())

@onready var _gui_bottom_row := %GuiBottomRow as Control
## todo: it's unfortunate that both message logs are always in the tree meaning
## they accept messages, do something about that
@onready var _dialogue_panel := %DialoguePanel as Control

# For which PlayableCharacter the dialog is currently open
var _open_dialog_char: PlayableCharacter:
	set(v):
		_open_dialog_char = v
		_update_portraits()


## Create portraits for given characters and listen for their state change
func set_characters(characters: Array[PlayableCharacter]) -> void:
	for character in characters:
		_register_character(character)


## Open interface containing player's inventory.
##
## todo: inventory should be also available in world map scene... Create some
## shared IngameGui that will be extended by both overworld and world map gui
## scenes?
func open_inventory() -> void:
	_player_inventor_slot.clear_or_instantiate(preload("res://gui/player_inventory/player_inventory_gui.tscn"))


## Close currently open right GUI control.
func close_inventory() -> void:
	_player_inventor_slot.clear()


## Open loot dialog for given lootable, so player can take the items
func open_lootable(lootable: Lootable) -> void:
	_close_all_lootable_dialogs()
	var dialog := preload("res://gui/loot_dialog/loot_dialog.tscn").instantiate() as LootDialog
	dialog.lootable = lootable
	add_child(dialog)
	_open_loot_dialogs[lootable] = weakref(dialog) # weakref for node prolly not needed, todo: test somehow


## Close dialog for given lootable (if exists)
func close_lootable(lootable: Lootable) -> void:
	var ref := _open_loot_dialogs.get(lootable, null) as WeakRef
	var dialog: LootDialog = ref.get_ref() if ref else null
	if dialog:
		remove_child(dialog)
		dialog.queue_free()
		_open_loot_dialogs.erase(lootable)
	if _open_loot_dialogs.size() == 0:
		_player_inventor_slot.clear()


## Hide most of the UI and start given dialogue with character considered as
## Actor
##
## todo: temp solution, all of this should prolly be in separate scene or
## something idk anymore
func start_dialogue(dialogue: DialogueGraph, actor: GameCharacter) -> void:
	var step := dialogue.get_begin_step()
	var ctx := DialogueContext.new()
	ctx.di = di
	ctx.dialogue = dialogue
	ctx.actor = actor
	while step != null:
		@warning_ignore("redundant_await")
		var port := await step.execute(ctx)
		step = dialogue.find_by_source(step.id, port)
	fade_out_bottom_dialogue()
	fade_in_bottom_default()
	await fade_in_bottom_default()
	_base_level.cutscene_active = false


## todo: all the fade methods are quite specific and shortsighted, works for
## now, generalize in the future I guess. Also maybe this should be handled
## using animation tree/graph or something
func fade_out_bottom_dialogue() -> void:
	await _fade_out(_dialogue_panel)


func fade_out_bottom_default() -> void:
	await _fade_out(_gui_bottom_row)


func fade_in_bottom_dialogue() -> void:
	await _fade_in(_dialogue_panel)


func fade_in_bottom_default() -> void:
	await _fade_in(_gui_bottom_row)


## Open character status screen for given character. If there is other
## character's dialog already open it will be closed.
func open_character_dialog(character: PlayableCharacter) -> void:
	if _open_dialog_char == character:
		_clear_existing_dialogs()
	else:
		_clear_existing_dialogs()
		var char_dialog := preload("res://gui/character_dialog/character_dialog.tscn").instantiate() as CharacterDialog
		char_dialog.setup(character)
		$Dialogs.add_child(char_dialog)
		char_dialog.close.connect(func () -> void: _clear_existing_dialogs())
		_open_dialog_char = character


## React to character selection changing. Display ability caster when single
## character selected.
func toggle_ability_caster_bar(caster_chara: PlayableCharacter = null) -> void:
	if caster_chara != null:
		var bar := preload("res://gui/ability_caster_bar/ability_caster_bar.tscn").instantiate() as AbilityCasterBar
		bar.caster = caster_chara
		_ability_caster_bar_slot.mount(bar)
	else:
		_ability_caster_bar_slot.clear()


## Prepare button for the character's portrait and store ref to the character
func _register_character(character: PlayableCharacter) -> void:
	var portrait := preload("res://gui/character_portrait/character_portrait.tscn").instantiate() as CharacterPortrait
	portrait.character = character
	$CharactersColumn.add_child(portrait)


## Update portraits according to currently open dialogs
func _update_portraits() -> void:
	for dialog: CharacterPortrait in $CharactersColumn.get_children():
		dialog.announce_dialog_open(_open_dialog_char)


## Remove all open char/player dialogs
func _clear_existing_dialogs() -> void:
	for existing_child in $Dialogs.get_children():
		$Dialogs.remove_child(existing_child)
		existing_child.queue_free()
	_open_dialog_char = null


## Resize handler of the message log frame
func _on_messages_frame_resize_top(top_offset: float) -> void:
	var frame := (%MessagesFrame as FramedDialog);
	frame.position.y -= top_offset
	frame.size.y += top_offset


func _close_all_lootable_dialogs() -> void:
	for lootable in _open_loot_dialogs:
		close_lootable(lootable)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("gui_scale_up") and not event.is_echo():
			get_tree().root.content_scale_factor *= 1.1
		elif event.is_action_pressed("gui_scale_down") and not event.is_echo():
			get_tree().root.content_scale_factor /= 1.1
		elif event.is_action("abort"):
			# todo: implement dialog stacking so esc always closes the last
			# opened dialog instead of everything
			if not event.is_pressed():
				_close_all_lootable_dialogs()


## Fade out given node to transparent and then hide it
func _fade_out(node: Control) -> void:
	if node.visible:
		var tween := create_tween()
		tween.tween_property(node, "modulate", Color(1, 0.5, 0.75, 0), 0.25)
		await tween.finished
		node.visible = false


## Make node visible and fade it in from transparent
func _fade_in(node: Control) -> void:
	if not node.visible:
		node.modulate = Color(1, 0.5, 0.75, 0)
		node.visible = true
		var tween := create_tween()
		tween.tween_property(node, "modulate", Color(1, 1, 1, 1), 0.25)
		await tween.finished
