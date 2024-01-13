# Logic controller during the out of combat time when player has full control
# over the party. Should be created by BaseLevel with all public properties
# set.

class_name ExplorationController
extends Node3D

var di = DI.new(self)

@onready var _terrain: TerrainWrapper = di.inject(TerrainWrapper)
@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)
@onready var _level_gui: LevelGui = di.inject(LevelGui)

var _ability_controller: AbilityController:
	get:
		return $AbilityController

### Public ###

func start_ability_pipeline(ctrl: AbilityController):
	add_child(ctrl)
	await _ability_controller.done
	_ability_controller.queue_free()

# Handler of clicking on playable character - be it portrait or model
func handle_character_click(character: GameCharacter, type: PlayableCharacter.InteractionType):
	if _ability_controller:
		_ability_controller.set_target_character(character)
	else:
		if character is PlayableCharacter:
			if type == PlayableCharacter.InteractionType.SELECT_ALONE:
				var characters = _controlled_characters.get_characters()
				for pc in characters:
					pc.selected = character == pc
			elif type == PlayableCharacter.InteractionType.SELECT_MULTI:
				character.selected = true

### Lifecycle ###

func _ready() -> void:
	_level_gui.character_selected.connect(handle_character_click)
	_controlled_characters.character_clicked.connect(handle_character_click)
	_controlled_characters.action_changed.connect(_on_character_action_changed)
	_terrain.input_event.connect(_on_terrain_input_event)

### Private ###

func _on_character_action_changed(_character, action):
	# fixme: when goal changes (e.g. another character stopped at that goal
	# first) the decal is not updated...
	if action is CharacterExplorationMovement:
		await action.goal_computed
	_update_goal_vectors()

# Update the _terrain decals for all characters that are currently walking
# somewhere
func _update_goal_vectors():
	var characters = _controlled_characters.get_characters()
	var goals = PackedVector3Array()
	goals.resize(4)
	goals.fill(Vector3(-20, -20, -20))
	for i in range(0, characters.size()):
		var action = characters[i].action
		if action is CharacterExplorationMovement:
			goals[i] = action.goal
	_terrain.set_next_pass_shader_parameter("goal_positions", goals)

# Event handler for all non-combat _terrain inputs -- selected character
# movement mostly
func _on_terrain_input_event(event: InputEvent, input_pos: Vector3):
	if event is InputEventMouseButton:
		if event.is_released():
			if _ability_controller:
				_ability_controller.set_target_point(input_pos)
			elif event.is_released() and event.button_index == MOUSE_BUTTON_RIGHT:
				_controlled_characters.walk_selected_to(input_pos)

func _abort_current_ability() -> void:
	if _ability_controller and _ability_controller.is_abortable():
		_ability_controller.queue_free()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action("abort") and not event.echo:
			_abort_current_ability()
