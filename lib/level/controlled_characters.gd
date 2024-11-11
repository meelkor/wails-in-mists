class_name ControlledCharacters
extends Node

## Signal emitting shortly after any of the controlled character's position
## changes. Can be used to run enemy logic, fow update etc.
signal position_changed(positions: Array[Vector3])

## Signal emitted when any of the controlled characters is clicked
signal character_clicked(character: PlayableCharacter, type: PlayableCharacter.InteractionType)

## Funnel for all controlled character's action change events
signal action_changed(character: PlayableCharacter, action: CharacterAction)

## Funnel for all controlled character's selected change events into single
## signal, which aggregates the result
signal selected_changed()

## Event emitted when any of the controlled characters requests casting an
## ability.
signal ability_casted(ctrl: AbilityRequest)

var changed_observer := ResourceObserver.new()

var _position_changed_needs_update := true
var _time_since_update := 0.0
var _selected_characters_changed := false

var _state_selected_characters := State.new()


## Add a new controlled character under this controller.
##
## This method should be always used instead of calling add_child directly
func spawn(characters: Array[PlayableCharacter], spawn_node: PlayerSpawn) -> void:
	var spawn_position := spawn_node.position
	var priority := 1.0
	for character in characters:
		priority -= 0.1
		var ctrl := preload("res://lib/controllers/player_controller.tscn").instantiate() as CharacterController
		ctrl.character = character
		add_child(ctrl)
		ctrl.navigation_agent.avoidance_priority = priority
		character.position = spawn_position
		character.position_changed.connect(func(_pos: Vector3) -> void: _position_changed_needs_update = true)
		character.action_changed.connect(func(action: CharacterAction) -> void: action_changed.emit(character, action))
		character.changed.connect(func () -> void: _selected_characters_changed = true)
		ctrl.clicked.connect(func (c: GameCharacter) -> void: character_clicked.emit(c, PlayableCharacter.InteractionType.SELECT_ALONE))
		spawn_position -= Vector3(1.5, 0, 1.5)
	changed_observer.update(characters)


## Get list of character instances this node currently controls
func get_characters() -> Array[PlayableCharacter]:
	var out: Array[PlayableCharacter] = []
	out.assign(get_children().map(func (ch: CharacterController) -> PlayableCharacter: return ch.character))
	return out


## Get list of selected characters
func get_selected() -> Array[PlayableCharacter]:
	var out: Array[PlayableCharacter] = []
	out.assign(get_characters().filter(func (chara: PlayableCharacter) -> bool: return chara.selected))
	return out


## Get controller for given character if it exists
func get_controller(character: PlayableCharacter) -> PlayerController:
	var c := get_children().filter(func (ctrl: CharacterController) -> bool: return ctrl.character == character)
	assert(c.size() == 1, "Trying to get controlelr for non-spawned character")
	return c[0]


func walk_selected_to(pos: Vector3) -> void:
	var controllers := get_children()
	var sample_controller := controllers[0] as CharacterController
	if sample_controller:
		var direction := pos.direction_to(sample_controller.position)
		var offset := 0.0
		for controller: PlayerController in controllers:
			if controller.pc.selected:
				controller.pc.action = CharacterExplorationMovement.new(pos + offset * direction)
				offset += 1


## Select given character (assuming it exists) deselecting every other
## character
func select(character: PlayableCharacter) -> void:
	for pc in get_characters():
		pc.selected = character == pc


func _process(delta: float) -> void:
	# FIXME: Hacky because I don't wanna create timer in this component, which
	# should only contain chracters
	# Also I am still not even sure whether I'm not overusing signals. Maybe
	# It would be better to just iterate over children and check
	# position_changed flag on in 100ms or something
	if _position_changed_needs_update:
		_position_changed_needs_update = false
		var positions: Array[Vector3] = []
		# todo: using GameCharacter type instead of CharacterController as the
		# lambda's argument breaks the game at the gdext call, try to reproduce
		# and report in godot or gdext repo
		positions.assign(get_children().map(func (ch: CharacterController) -> Vector3: return ch.position))
		position_changed.emit(positions)
		_time_since_update = 0
	else:
		_time_since_update += delta

	if _selected_characters_changed:
		_selected_characters_changed = false
		_emit_updated_selected()


func _emit_updated_selected() -> void:
	var selected_chars: Array[PlayableCharacter] = []
	selected_chars.assign(get_characters().filter(func (ch: PlayableCharacter) -> bool: return ch.selected))
	if _state_selected_characters.changed(selected_chars):
		selected_changed.emit()
