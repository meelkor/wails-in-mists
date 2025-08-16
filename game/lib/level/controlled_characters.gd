class_name ControlledCharacters
extends Node

## Signal emitting shortly after any of the controlled character's position
## changes. Can be used to run enemy logic, fow update etc.
signal position_changed(positions: Array[Vector3])

## Signal emitted when any of the controlled characters is clicked
signal character_clicked(character: PlayableCharacter, type: GameCharacter.InteractionType)

## Funnel for all controlled character's selected change events into single
## signal, which aggregates the result
signal selected_changed()

## Event emitted when any of the controlled characters requests casting an
## ability.
signal ability_casted(ctrl: AbilityRequest)

## Changed singals of all controlled PCs merged into one signal
var changed_observer := ResourceObserver.new()

## Action changed singals of all controlled PCs merged into one signal
var action_changed_observer := ResourceObserver.new(&"action_changed")

var _position_changed_needs_update := true
var _time_since_update := 0.0
var _selected_characters_changed := false

var _state_selected_characters := State.new()

var _some_character_selected: bool = false


## Add a new controlled character under this controller.
##
## This method should be always used instead of calling add_child directly
func spawn(characters: Array[PlayableCharacter], spawn_node: PlayerSpawn) -> void:
	var spawn_position := spawn_node.position
	for character in characters:
		var ctrl := preload("res://lib/controllers/player_controller.tscn").instantiate() as CharacterController
		ctrl.character = character
		add_child(ctrl)
		character.position = spawn_position
		character.position_changed.connect(func(_pos: Vector3) -> void: _position_changed_needs_update = true)
		character.changed.connect(func () -> void: _selected_characters_changed = true)
		character.clicked.connect(func (type: GameCharacter.InteractionType) -> void: character_clicked.emit(character, type))
		spawn_position -= Vector3(1.5, 0, 1.5)
	changed_observer.update(characters)
	action_changed_observer.update(characters)


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


func walk_selected_to(pos: Vector3) -> void:
	var controllers := get_children()
	var sample_controller := controllers[0] as CharacterController
	if sample_controller:
		var direction := pos.direction_to(sample_controller.position)
		var offset := 0.0
		for controller: PlayerController in controllers:
			if controller.pc.selected and controller.pc.is_free():
				controller.pc.action = CharacterExplorationMovement.new(pos + offset * direction)
				offset += 1


## Return true if at least one character is selected
func has_selected() -> bool:
	return _some_character_selected


## Select given character (assuming it exists) deselecting every other
## character
func select(character: PlayableCharacter) -> void:
	for pc in get_characters():
		pc.selected = character == pc


## Get selected character on which consumable effects (and possibly other
## effects) should be applied. Currently the first selected character. Assumes
## the order of character controller nodes in this node represents the order of
## the characters in player state.
func get_selected_main() -> PlayableCharacter:
	return get_selected()[0] if has_selected() else null


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
		_some_character_selected = get_selected().size() > 0
		_emit_updated_selected()


func _emit_updated_selected() -> void:
	var selected_chars: Array[PlayableCharacter] = []
	selected_chars.assign(get_characters().filter(func (ch: PlayableCharacter) -> bool: return ch.selected))
	if _state_selected_characters.changed(selected_chars):
		selected_changed.emit()
