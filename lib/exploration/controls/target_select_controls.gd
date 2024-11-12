class_name TargetSelectControls
extends Node

const PROJECT_MATERIAL = preload("res://materials/terrain_projections.tres")

enum Type {
	TERRAIN = 0b01,
	CHARACTER = 0b10,
}

var di := DI.new(self)

@onready var _terrain: TerrainWrapper = di.inject(TerrainWrapper)
@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)
@onready var _spawned_npcs: SpawnedNpcs = di.inject(SpawnedNpcs)
@onready var _level_gui: LevelGui = di.inject(LevelGui)

var _circle_projector := CircleProjector.new()

var _after_reset := false

var _current_request: AbilityRequest

var target_type_mask: int = 0

signal selected(target: AbilityTarget)


## Configure controls instance  based on the given ability and return the
## selected signal.
func select_for_ability(request: AbilityRequest) -> Signal:
	_current_request = request
	if _current_request.ability.target_type == Ability.TargetType.AOE:
		target_type_mask = TargetSelectControls.Type.TERRAIN | TargetSelectControls.Type.CHARACTER
	elif _current_request.ability.target_type == Ability.TargetType.SINGLE:
		target_type_mask = TargetSelectControls.Type.CHARACTER
	return selected


func _enter_tree() -> void:
	GameCursor.use_select_target()


func _exit_tree() -> void:
	_after_reset = true
	GameCursor.use_default()
	_update_targeted_characters(true)
	_circle_projector.clear()


func _ready() -> void:
	_terrain.input_event.connect(_on_terrain_input_event)
	_level_gui.character_selected.connect(_on_character_click)
	_controlled_characters.character_clicked.connect(func (character: PlayableCharacter, _type: Variant) -> void: _on_character_click(character))
	_spawned_npcs.character_clicked.connect(_on_character_click)
	_controlled_characters.changed_observer.changed.connect(_update_targeted_characters)
	_spawned_npcs.changed_observer.changed.connect(_update_targeted_characters)


func _process(_delta: float) -> void:
	_circle_projector.reset()
	if GameCharacter.hovered_character:
		_circle_projector.add_characters([GameCharacter.hovered_character], 1.0, 0.5)
	_circle_projector.add_characters([_current_request.caster], 1.0)
	_circle_projector.add_circle(_current_request.caster.position, _current_request.ability.reach, Utils.Vector.rgb(Config.Palette.REACH_CIRCLE), 0.8, 1.0)
	_circle_projector.apply()


## Event handler for all non-combat _terrain inputs -- selected character
## movement mostly
func _on_terrain_input_event(event: InputEvent, pos: Vector3) -> void:
	var btn_event := event as InputEventMouseButton
	if btn_event:
		if btn_event.is_released() and btn_event.button_index == MOUSE_BUTTON_LEFT:
			if target_type_mask & Type.TERRAIN:
				selected.emit(AbilityTarget.from_position(pos))
				_current_request = null


func _on_character_click(character: GameCharacter) -> void:
	if target_type_mask & Type.CHARACTER:
		selected.emit(AbilityTarget.from_character(character))
		_current_request = null


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	# this should be handled in controls!
	if key_event and key_event.is_action("abort") and not key_event.echo:
		selected.emit(null)
		_current_request = null


## Go through all characters and udpate their targeted property. Ugly, rework
## as described in targeted docs
func _update_targeted_characters(reset: bool = false) -> void:
	# the need for this condition is also caused by the whole dumbass loop of
	# events
	if not _after_reset or reset:
		var all_chars := []
		all_chars.append_array(_controlled_characters.get_characters())
		all_chars.append_array(_spawned_npcs.get_characters())
		for character: GameCharacter in all_chars:
			character.targeted = false if reset else character.hovered
