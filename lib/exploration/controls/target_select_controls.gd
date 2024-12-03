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

var _circle_projector := CircleProjector.new()

var _after_reset := false

var _current_request: AbilityRequest

var _target_type_mask: int = 0

var _last_terrain_pos := Vector3.ZERO

var _sphere: SphereShape3D
var _area: Area3D

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
	elif _current_request.ability.target_type == Ability.TargetType.SINGLE:
		_target_type_mask = TargetSelectControls.Type.CHARACTER
	return selected


func _enter_tree() -> void:
	GameCursor.use_select_target()


func _exit_tree() -> void:
	_after_reset = true
	GameCursor.use_default()
	_update_targeted_characters(true)
	_circle_projector.clear()


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
	_controlled_characters.changed_observer.changed.connect(_update_targeted_characters)
	_spawned_npcs.changed_observer.changed.connect(_update_targeted_characters)


func _process(_delta: float) -> void:
	_circle_projector.reset()
	var caster := _current_request.caster
	var ability := _current_request.ability
	var caster_targeted := false

	# todo: less conditions
	if ability.target_type == Ability.TargetType.SELF:
		caster_targeted = true
	else:
		# ability reach
		_circle_projector.add_circle(_current_request.caster.position, _current_request.ability.reach, Utils.Vector.rgb(Config.Palette.REACH_CIRCLE), 0.5, 1.0)
		if ability.target_type == Ability.TargetType.SINGLE and GameCharacter.hovered_character:
			caster_targeted = GameCharacter.hovered_character == caster
			if not caster_targeted:
				# single character target
				_circle_projector.add_characters([GameCharacter.hovered_character], 1.0, 0.5)
		elif ability.target_type == Ability.TargetType.AOE:
			var aoe_pos := GameCharacter.hovered_character.position if GameCharacter.hovered_character else _last_terrain_pos
			# AOE circle
			_circle_projector.add_circle(aoe_pos, ability.aoe_size, Utils.Vector.rgb(Config.Palette.AOE_CIRCLE), 0.8, 0.2)
			for body: CharacterController in _area.get_overlapping_bodies():
				if body.character == caster:
					caster_targeted = true
				else:
					# AOE's non-caster target
					_circle_projector.add_characters([body.character], 1.0, 0.5)
	if caster_targeted:
		# self target circle
		_circle_projector.add_characters([_current_request.caster], 1.0, 0.5)
	else:
		# selected char circle
		_circle_projector.add_characters([_current_request.caster], 1.0)
	_circle_projector.apply()


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
	elif motion_event:
		_last_terrain_pos = pos
		_area.global_position = pos



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
