## Logic controller during the out of combat time when player has full control
## over the party. Should be created by BaseLevel with all public properties
## set.
class_name ExplorationController
extends Node3D

const PROJECT_MATERIAL = preload("res://materials/terrain_projections.tres")

var di := DI.new(self)

@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)
@onready var _ability_resolver: AbilityResolver = di.inject(AbilityResolver)

var _controls: NodeSlot = NodeSlot.new(self, "Controls")

## Dict<GameCharacter, AbilityRequest> which have desired position set and the
## controller should handle pathfinding and movement to that position. Since
## the target's position may change  over time (target character moving), we
## need to handle it in process. Once the target is in reach, we should execute
## ability and remove it from here.
var _requested_abilities: Dictionary[GameCharacter, AbilityRequest] = {}


func _ready() -> void:
	_controlled_characters.changed_observer.changed.connect(_update_goal_vectors)
	_controlled_characters.ability_casted.connect(_start_ability_pipeline)
	_controls.mount(FreeMovementControls.new())
	_update_goal_vectors()


func _process(_d: float) -> void:
	for character: GameCharacter in _requested_abilities.keys():
		var request: AbilityRequest = _requested_abilities[character]
		# todo: check vision using raycasting I guess
		if request.can_reach():
			_requested_abilities.erase(character)
			await _ability_resolver.execute(request).completed
			character.action = CharacterIdle.new()
		else:
			request.move_to_target()


func _exit_tree() -> void:
	var img := Image.create_from_data(0, 0, false, Image.FORMAT_RGBF, PackedByteArray())
	var tex := ImageTexture.create_from_image(img)
	PROJECT_MATERIAL.set_shader_parameter("goal_positions", tex)


func _start_ability_pipeline(request: AbilityRequest) -> void:
	if request.ability.target_type != Ability.TargetType.SELF:
		var target_select: TargetSelectControls = _controls.mount(TargetSelectControls.new())
		request.target = await target_select.select_for_ability(request)
		_controls.get_or_new(FreeMovementControls)
	else:
		request.target = AbilityTarget.from_none()

	if request.target:
		_requested_abilities[request.caster] = request


## Update the _terrain decals for all characters that are currently walking
## somewhere
func _update_goal_vectors() -> void:
	# todo: is it expected that even after removal from tree we are still
	# catching some changed signals?
	if not is_inside_tree():
		return
	# Wait for the navmesh to be rebaked and path to be calculated.
	await get_tree().process_frame
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
	PROJECT_MATERIAL.set_shader_parameter("goal_positions", t)
