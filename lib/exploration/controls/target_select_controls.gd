class_name TargetSelectControls
extends Node

enum Type {
	TERRAIN = 0b01,
	CHARACTER = 0b10,
}

var di := DI.new(self)

@onready var _terrain: TerrainWrapper = di.inject(TerrainWrapper)
@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)
@onready var _spawned_npcs: SpawnedNpcs = di.inject(SpawnedNpcs)
@onready var _level_gui: LevelGui = di.inject(LevelGui)

var _projection_mat := preload("res://materials/terrain_projections.tres")

var _after_reset := false

var target_type_mask: int = 0

signal selected(target: AbilityTarget)


## Configure controls instance  based on the given ability and return the
## selected signal.
func select_for_ability(caster: GameCharacter, ability: Ability) -> Signal:
	_projection_mat.set_shader_parameter("aoe_visible", true)
	_projection_mat.set_shader_parameter("aoe", Vector4(caster.position.x, caster.position.y, caster.position.z, ability.reach))

	if ability.target_type == Ability.TargetType.AOE:
		target_type_mask = TargetSelectControls.Type.TERRAIN | TargetSelectControls.Type.CHARACTER
	elif ability.target_type == Ability.TargetType.SINGLE:
		target_type_mask = TargetSelectControls.Type.CHARACTER
	return selected


func _enter_tree() -> void:
	GameCursor.use_select_target()


func _exit_tree() -> void:
	_after_reset = true
	_projection_mat.set_shader_parameter("aoe_visible", false)
	GameCursor.use_default()
	_update_targeted_characters(true)


func _ready() -> void:
	_terrain.input_event.connect(_on_terrain_input_event)
	_level_gui.character_selected.connect(_on_character_click)
	_controlled_characters.character_clicked.connect(func (character: PlayableCharacter, _type: Variant) -> void: _on_character_click(character))
	_spawned_npcs.character_clicked.connect(_on_character_click)
	_controlled_characters.changed_observer.changed.connect(_update_targeted_characters)
	_spawned_npcs.changed_observer.changed.connect(_update_targeted_characters)


## Event handler for all non-combat _terrain inputs -- selected character
## movement mostly
func _on_terrain_input_event(event: InputEvent, pos: Vector3) -> void:
	var btn_event := event as InputEventMouseButton
	if btn_event:
		if btn_event.is_released() and btn_event.button_index == MOUSE_BUTTON_LEFT:
			if target_type_mask & Type.TERRAIN:
				selected.emit(AbilityTarget.from_position(pos))


func _on_character_click(character: GameCharacter) -> void:
	if target_type_mask & Type.CHARACTER:
		selected.emit(AbilityTarget.from_character(character))


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	# this should be handled in controls!
	if key_event and key_event.is_action("abort") and not key_event.echo:
		selected.emit(null)


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
