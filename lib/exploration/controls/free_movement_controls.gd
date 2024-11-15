## Controls node which allows user to freely select and move characters when in
## tree
class_name FreeMovementControls
extends Node


## Max movement delta before mouse click on terrain changes into area select
const CLICK_MAX_DELTA = 16.

var di := DI.new(self)

@onready var _terrain: TerrainWrapper = di.inject(TerrainWrapper)
@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)
@onready var _level_gui: LevelGui = di.inject(LevelGui)
@onready var _level_camera: LevelCamera = di.inject(LevelCamera)
@onready var _base_level: BaseLevel = di.inject(BaseLevel)

var _circle_projector := CircleProjector.new()

var _selecting_from: Vector2 = Vector2.ZERO

var _line2d: Line2D

var _mouse_down_pos := Vector2.ZERO


func _ready() -> void:
	_line2d = Line2D.new()
	_line2d.default_color = Config.Palette.PRIMARY
	_line2d.width = 1
	add_child(_line2d)
	_terrain.input_event.connect(_on_terrain_input_event)
	_controlled_characters.character_clicked.connect(_on_character_click)
	_base_level.lootable_hovered.connect(_on_lootable_hovered)
	_base_level.loot_requested.connect(_on_loot_request)


func _process(_delta: float) -> void:
	_circle_projector.reset()
	if GameCharacter.hovered_character:
		_circle_projector.add_characters([GameCharacter.hovered_character], Config.HOVER_OPACITY)
	_circle_projector.add_selected_characters(_controlled_characters.get_characters())
	_circle_projector.apply()


func _exit_tree() -> void:
	_circle_projector.clear()


func _on_lootable_hovered(lootable_mesh: LootableMesh, state: bool) -> void:
	if state:
		GameCursor.use_loot()
	else:
		GameCursor.use_default()
	lootable_mesh.highlighted = state


func _on_loot_request(lootable_mesh: LootableMesh) -> void:
	lootable_mesh.open()


## Event handler for all non-combat _terrain inputs -- selected character
## movement mostly
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
func _on_character_click(character: PlayableCharacter, type: GameCharacter.InteractionType) -> void:
	if type == GameCharacter.InteractionType.SELECT:
		_controlled_characters.select(character)
	elif type == GameCharacter.InteractionType.SELECT_MULTI:
		character.selected = true
	elif type == GameCharacter.InteractionType.INSPECT:
		_level_gui.open_character_dialog(character)


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
	var dims := _selecting_from - current_pos
	return Rect2(
		Vector2(
			min(current_pos.x, _selecting_from.x) as float,
			min(current_pos.y, _selecting_from.y) as float,
		),
		dims.abs(),
	)


func _is_rect_selecting() -> bool:
	return _selecting_from != Vector2.ZERO


func _draw_rect2_as_line(line2d: Line2D, rect: Rect2) -> void:
	var bottom_right := rect.position + rect.size
	var top_left := rect.position
	line2d.clear_points()
	line2d.add_point(top_left)
	line2d.add_point(Vector2(bottom_right.x, top_left.y))
	line2d.add_point(bottom_right)
	line2d.add_point(Vector2(top_left.x, bottom_right.y))
	line2d.add_point(top_left)


func _select_characters_by_rect(rect: Rect2) -> void:
	for character in _controlled_characters.get_characters():
		character.selected = rect.has_point(_level_camera.unproject_position(character.position))
