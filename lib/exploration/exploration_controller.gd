# Logic controller during the out of combat time when player has full control
# over the party. Should be created by BaseLevel with all public properties
# set.

class_name ExplorationController
extends Node3D

var terrain: TerrainWrapper

# Is this good idea???
var controlled_characters: ControlledCharacters

var _ability_controller: AbilityController:
	get:
		return $AbilityController

### Public ###

func start_ability_pipeline(ctrl: AbilityController):
	add_child(ctrl)
	await ctrl.target_received()
	print("target received")

# Handler of clicking on playable character - be it portrait or model
func handle_character_click(character: GameCharacter, type: PlayableCharacter.InteractionType):
	if _ability_controller:
		_ability_controller.set_target_character(character)
	else:
		if character is PlayableCharacter:
			if type == PlayableCharacter.InteractionType.SELECT_ALONE:
				var characters = controlled_characters.get_characters()
				for pc in characters:
					pc.selected = character == pc
			elif type == PlayableCharacter.InteractionType.SELECT_MULTI:
				character.selected = true

# func start_ability_pipeline(ctrl: ) -> void:

### Lifecycle ###

func _ready() -> void:
	assert(terrain, "Created ExplorationController without TerrainWrapper instance")
	assert(controlled_characters, "Created ExplorationController without ControlledCharacters instance")
	controlled_characters.action_changed.connect(_on_character_action_changed)
	terrain.input_event.connect(_on_terrain_input_event)

### Private ###

func _on_character_action_changed(_character, action):
	# fixme: when goal changes (e.g. another character stopped at that goal
	# first) the decal is not updated...
	if action is CharacterExplorationMovement:
		await action.goal_computed
	_update_goal_vectors()

# Update the terrain decals for all characters that are currently walking
# somewhere
func _update_goal_vectors():
	var characters = controlled_characters.get_characters()
	var goals = PackedVector3Array()
	goals.resize(4)
	goals.fill(Vector3(-20, -20, -20))
	for i in range(0, characters.size()):
		var action = characters[i].action
		if action is CharacterExplorationMovement:
			goals[i] = action.goal
	terrain.set_next_pass_shader_parameter("goal_positions", goals)

# Event handler for all non-combat terrain inputs -- selected character
# movement mostly
func _on_terrain_input_event(event: InputEvent, input_pos: Vector3):
	if event is InputEventMouseButton:
		if event.is_released():
			if _ability_controller:
				_ability_controller.set_target_point(input_pos)
			elif event.is_released() and event.button_index == MOUSE_BUTTON_RIGHT:
				controlled_characters.walk_selected_to(input_pos)
