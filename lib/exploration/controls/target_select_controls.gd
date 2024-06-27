class_name TargetSelectControls
extends Node

enum Type {
	TERRAIN = 0b01,
	CHARACTER = 0b10,
}

var di = DI.new(self)

@onready var _terrain: TerrainWrapper = di.inject(TerrainWrapper)
@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)
@onready var _level_gui: LevelGui = di.inject(LevelGui)

signal _terrain_selected(pos: Vector3)

signal _character_selected(character: GameCharacter)

signal _selected(target: AbilityTarget)

### Public ###

func get_selection_signal(types: int) -> Signal:
	if types & Type.TERRAIN:
		_terrain_selected.connect(func (pos): _selected.emit(AbilityTarget.from_position(pos)))
	if types & Type.CHARACTER:
		_character_selected.connect(func (character): _selected.emit(AbilityTarget.from_character(character)))
	return _selected

### Lifecycle ###

func _enter_tree() -> void:
	GameCursor.use_select_target()

func _exit_tree() -> void:
	GameCursor.use_default()

func _ready() -> void:
	_terrain.input_event.connect(_on_terrain_input_event)
	_level_gui.character_selected.connect(_on_character_click)
	_controlled_characters.character_clicked.connect(_on_character_click)

### Private ###

# Event handler for all non-combat _terrain inputs -- selected character
# movement mostly
func _on_terrain_input_event(event: InputEvent, input_pos: Vector3):
	if event is InputEventMouseButton:
		if event.is_released() and event.button_index == MOUSE_BUTTON_LEFT:
			_terrain_selected.emit(input_pos)

func _on_character_click(character: GameCharacter, _type):
	_character_selected.emit(character)
