## Logic controller during the out of combat time when player has full control
## over the party. Should be created by BaseLevel with all public properties
## set.
class_name ExplorationController
extends Node3D

var di := DI.new(self)

@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)
@onready var _ability_resolver: AbilityResolver = di.inject(AbilityResolver)

var _projection_mat := preload("res://materials/terrain_projections.tres") as ShaderMaterial

var _controls: NodeSlot = NodeSlot.new(self, "Controls")

## Dict<GameCharacter, AbilityRequest> which have desired position set and the
## controller should handle pathfinding and movement to that position. Since
## the target's position may change  over time (target character moving), we
## need to handle it in process. Once the target is in reach, we should execute
## ability and remove it from here.
var _requested_abilities: Dictionary = {}


func _ready() -> void:
	_controlled_characters.action_changed.connect(_on_character_action_changed)
	_controlled_characters.ability_casted.connect(_start_ability_pipeline)
	_controls.mount(FreeMovementControls.new())
	_update_goal_vectors()


func _process(_d: float) -> void:
	for character: GameCharacter in _requested_abilities.keys():
		var request: AbilityRequest = _requested_abilities[character]
		# todo: check vision using raycasting I guess
		if request.can_reach():
			_ability_resolver.execute(request)
			_requested_abilities.erase(character)
		else:
			request.move_to_target()


func _exit_tree() -> void:
	var img := Image.create_from_data(0, 0, false, Image.FORMAT_RGBF, PackedByteArray())
	var tex := ImageTexture.create_from_image(img)
	_projection_mat.set_shader_parameter("goal_positions", tex)


func _start_ability_pipeline(process: AbilityRequest) -> void:
	if process.ability.target_type != Ability.TargetType.SELF:
		var target_select: TargetSelectControls = _controls.get_or_new(TargetSelectControls)
		process.target = await target_select.select_for_ability(process.caster, process.ability)
		_controls.get_or_new(FreeMovementControls)
	else:
		process.target = AbilityTarget.from_none()

	if process.target:
		_requested_abilities[process.caster] = process


func _on_character_action_changed(_character: GameCharacter, action: CharacterAction) -> void:
	# fixme: when goal changes (e.g. another character stopped at that goal
	# first) the decal is not updated...
	var movement := action as CharacterExplorationMovement
	if movement:
		await movement.goal_computed
	_update_goal_vectors()


## Update the _terrain decals for all characters that are currently walking
## somewhere
func _update_goal_vectors() -> void:
	var characters := _controlled_characters.get_characters()
	var actions := characters.map(func (character: PlayableCharacter) -> CharacterAction: return character.action)
	var movements := actions.filter(func (a: CharacterAction) -> bool: return a is CharacterExplorationMovement)
	var image_data := PackedFloat32Array()
	image_data.resize((1 + movements.size()) * 3)
	image_data[0] = 0.0
	image_data[1] = 0.0
	image_data[2] = 0.0

	for i in range(0, movements.size()):
		var action: CharacterExplorationMovement = movements[i]
		image_data[3 * (i + 1) + 0] = action.goal.x
		image_data[3 * (i + 1) + 1] = action.goal.y
		image_data[3 * (i + 1) + 2] = action.goal.z

	var img := Image.create_from_data(1 + movements.size(), 1, false, Image.FORMAT_RGBF, image_data.to_byte_array())
	var t := ImageTexture.create_from_image(img)
	_projection_mat.set_shader_parameter("goal_positions", t)
