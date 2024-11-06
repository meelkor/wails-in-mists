# Controls node which allows user to freely select and move characters when in
# tree

class_name FreeMovementControls
extends Node

var di := DI.new(self)

@onready var _terrain: TerrainWrapper = di.inject(TerrainWrapper)
@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)
@onready var _level_gui: LevelGui = di.inject(LevelGui)
@onready var _level_camera: LevelCamera = di.inject(LevelCamera)

## Max movement delta before mouse click on terrain changes into area select
const CLICK_MAX_DELTA = 16.

var _selecting_from: Vector2 = Vector2.ZERO

var _line2d: Line2D

var _mouse_down_pos := Vector2.ZERO

### Lifecycle ###

func _ready() -> void:
	_line2d = Line2D.new()
	_line2d.default_color = Palette.PRIMARY
	_line2d.width = 1
	add_child(_line2d)
	_terrain.input_event.connect(_on_terrain_input_event)
	_level_gui.character_selected.connect(_on_character_click)
	_controlled_characters.character_clicked.connect(_on_character_click)

### Private ###

# Event handler for all non-combat _terrain inputs -- selected character
# movement mostly
func _on_terrain_input_event(event: InputEvent, input_pos: Vector3) -> void:
	var btn_event := event as InputEventMouseButton
	if btn_event:
		if btn_event.button_index == MOUSE_BUTTON_LEFT:
			if btn_event.pressed:
				_mouse_down_pos = btn_event.position
			else:
				if _mouse_down_pos.distance_to(btn_event.position) <= CLICK_MAX_DELTA:
					_controlled_characters.walk_selected_to(input_pos)


## Handler of clicking on playable character - be it portrait or model
func _on_character_click(character: GameCharacter, type: PlayableCharacter.InteractionType) -> void:
	var pc := character as PlayableCharacter
	if pc:
		if type == PlayableCharacter.InteractionType.SELECT_ALONE:
			_controlled_characters.select(pc)
		elif type == PlayableCharacter.InteractionType.SELECT_MULTI:
			pc.selected = true


## Observe any mouse click-dragging in the 3D world and us it for
## area-selecting of characters
func _unhandled_input(e: InputEvent) -> void:
	var btn_event := e as InputEventMouseButton
	var motion_event := e as InputEventMouseMotion
	if btn_event:
		if btn_event.button_index == MOUSE_BUTTON_LEFT:
			if btn_event.pressed:
				_selecting_from = btn_event.position
			elif _is_rect_selecting():
				if _selecting_from.distance_to(btn_event.position) > CLICK_MAX_DELTA:
					var rect := _get_selection_rect(btn_event.position)
					_select_characters_by_rect(rect)
				_line2d.clear_points()
				_selecting_from = Vector2.ZERO
	elif motion_event is InputEventMouseMotion:
		if motion_event.button_mask == MOUSE_BUTTON_MASK_LEFT && _is_rect_selecting():
			var rect := _get_selection_rect(motion_event.position)
			_draw_rect2_as_line(_line2d, rect)


func _get_selection_rect(current_pos: Vector2) -> Rect2:
	var dims = _selecting_from - current_pos
	return Rect2(
		Vector2(
			min(current_pos.x, _selecting_from.x),
			min(current_pos.y, _selecting_from.y),
		),
		dims.abs(),
	)

func _is_rect_selecting() -> bool:
	return _selecting_from != Vector2.ZERO

func _draw_rect2_as_line(line2d: Line2D, rect: Rect2) -> void:
	var bottom_right = rect.position + rect.size
	var top_left = rect.position
	line2d.clear_points()
	line2d.add_point(top_left)
	line2d.add_point(Vector2(bottom_right.x, top_left.y))
	line2d.add_point(bottom_right)
	line2d.add_point(Vector2(top_left.x, bottom_right.y))
	line2d.add_point(top_left)

func _select_characters_by_rect(rect: Rect2) -> void:
	for character in _controlled_characters.get_characters():
		character.selected = rect.has_point(_level_camera.unproject_position(character.position))
