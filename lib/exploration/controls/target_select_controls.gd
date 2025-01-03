class_name TargetSelectControls
extends Node

const PROJECT_MATERIAL = preload("res://materials/terrain_projections.tres")

enum Type {
	TERRAIN = 0b01,
	CHARACTER = 0b10,
}

var di := DI.new(self)

@onready var _terrain: Terrain = di.inject(Terrain)
@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)
@onready var _spawned_npcs: SpawnedNpcs = di.inject(SpawnedNpcs)

var _after_reset := false

var _current_request: AbilityRequest

var _target_type_mask: int = 0

var _last_terrain_pos := Vector3.ZERO

var _sphere: SphereShape3D
var _area: Area3D

var _aoe_circle := TerrainCircle.new()
var _hovered_char_circle := TerrainCircle.new()

signal selected(target: AbilityTarget)


## Configure controls instance  based on the given ability and return the
## selected signal.
func select_for_ability(request: AbilityRequest) -> Signal:
	assert(not _current_request, "Target select controls already used")
	_current_request = request
	if _current_request.ability.target_type == Ability.TargetType.AOE:
		_area.process_mode = Node.PROCESS_MODE_INHERIT
		_sphere.radius = request.ability.aoe_size
		_target_type_mask = TargetSelectControls.Type.TERRAIN | TargetSelectControls.Type.CHARACTER

		_aoe_circle = TerrainCircle.new()
		_aoe_circle.color = Color(Config.Palette.AOE_CIRCLE, 0.5)
		_aoe_circle.fade = 1.0
		add_child(_aoe_circle)
	elif _current_request.ability.target_type == Ability.TargetType.SINGLE:
		_target_type_mask = TargetSelectControls.Type.CHARACTER
		var range_circle := TerrainCircle.new()
		range_circle.color = Config.Palette.AOE_CIRCLE
		range_circle.radius = request.ability.reach
		range_circle.track_node(request.caster.get_controller())
		add_child(range_circle)
		_hovered_char_circle.visible = false
		_hovered_char_circle.dashed = 4
		add_child(_hovered_char_circle)
	elif _current_request.ability.target_type == Ability.TargetType.SELF:
		var self_circle := TerrainCircle.new()
		self_circle.color = request.caster.get_color()
		self_circle.radius = request.caster.model_radius
		self_circle.dashed = 4
		self_circle.track_node(request.caster.get_controller())
		add_child(self_circle)

	return selected


func _enter_tree() -> void:
	GameCursor.use_select_target()


func _exit_tree() -> void:
	_after_reset = true
	GameCursor.use_default()


func _ready() -> void:
	# todo: make into scene?
	_area = Area3D.new()
	_area.process_mode = Node.PROCESS_MODE_DISABLED
	_area.collision_layer = 0
	_area.collision_mask = 1
	var collider := CollisionShape3D.new()
	_sphere = SphereShape3D.new()
	collider.shape = _sphere
	_area.add_child(collider)
	add_child(_area)

	_terrain.input_event.connect(_on_terrain_input_event)
	_controlled_characters.character_clicked.connect(_on_character_click)
	_spawned_npcs.character_clicked.connect(_on_character_click)
	GameCharacter.hovered_changed.connect(_on_character_hover)


## Event handler for all non-combat _terrain inputs -- selected character
## movement mostly
func _on_terrain_input_event(event: InputEvent, pos: Vector3) -> void:
	var btn_event := event as InputEventMouseButton
	var motion_event := event as InputEventMouseMotion
	if btn_event:
		if btn_event.is_released() and btn_event.button_index == MOUSE_BUTTON_LEFT:
			if _target_type_mask & Type.TERRAIN:
				selected.emit(AbilityTarget.from_position(pos))
				_current_request = null
			elif _target_type_mask == 0:
				selected.emit(AbilityTarget.from_none())
				_current_request = null

	elif motion_event:
		_last_terrain_pos = pos
		_area.global_position = pos
		_aoe_circle.global_position = pos


func _on_character_click(character: GameCharacter, type: GameCharacter.InteractionType) -> void:
	if _target_type_mask & Type.CHARACTER and type == GameCharacter.InteractionType.SELECT:
		selected.emit(AbilityTarget.from_character(character))
		_current_request = null


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	# this should be handled in controls!
	if key_event and key_event.is_action("abort") and not key_event.echo:
		selected.emit(null)
		_current_request = null


func _on_character_hover() -> void:
	var hovered := GameCharacter.hovered_character
	if hovered:
		_hovered_char_circle.visible = true
		_hovered_char_circle.update_for_character(hovered, 1.0)
	else:
		_hovered_char_circle.visible = false
