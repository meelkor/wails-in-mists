class_name ControlledCharacters
extends Node

# Signal emitting shortly after any of the controlled character's position
# changes. Can be used to run enemy logic, fow update etc.
signal position_changed(positions)

# Signal emitted when any of the controlled characters is clicked
signal character_clicked(character: PlayableCharacter, type: PlayableCharacter.InteractionType)

# Funnel for all controlled character's action change events
signal action_changed(character: PlayableCharacter, action: CharacterAction)

var position_changed_needs_update = true
var time_since_update = 0

### Public ###

# Add a new controlled character under this controller.
#
# This method should be always used instead of calling add_child directly
func spawn(characters: Array[PlayableCharacter], spawn_node: PlayerSpawn):
	var spawn_position = spawn_node.position
	for character in characters:
		var ctrl = preload("res://logic/controllers/player_controller.tscn").instantiate()
		ctrl.character = character
		add_child(ctrl)
		character.position = spawn_position
		character.position_changed.connect(func(_pos): position_changed_needs_update = true)
		character.action_changed.connect(func(action): action_changed.emit(character, action))
		ctrl.clicked.connect(func (c): character_clicked.emit(c, PlayableCharacter.InteractionType.SELECT_ALONE))
		spawn_position -= Vector3(0.8, 0, 0.8)

# Get list of character instances this node currently controls
func get_characters() -> Array[PlayableCharacter]:
	var out: Array[PlayableCharacter] = []
	out.assign(get_children().map(func (ch): return ch.character))
	return out

func walk_selected_to(pos: Vector3):
	var controllers = get_children()
	var sample_controller: CharacterController = controllers[0] as CharacterController
	if sample_controller:
		var direction = pos.direction_to(sample_controller.position)
		var offset = 0
		for controller in controllers:
			if controller.character.selected:
				controller.character.action = CharacterExplorationMovement.new(pos + offset * direction)
				offset += 1

### Lifecycle ###

func _process(delta: float) -> void:
	# FIXME: Hacky because I don't wanna create timer in this component, which
	# should only contain chracters
	# Also I am still not even sure whether I'm not overusing signals. Maybe
	# It would be better to just iterate over children and check
	# position_changed flag on in 100ms or something
	if position_changed_needs_update and time_since_update > 0.1:
		position_changed_needs_update = false
		var positions: Array[Vector3] = []
		# fml: https://github.com/godotengine/godot/issues/72566 (I am one more
		# step closer to switching to rust)
		positions.assign(get_children().map(func (ch): return ch.position))
		position_changed.emit(positions)
		time_since_update = 0
	else:
		time_since_update += delta
