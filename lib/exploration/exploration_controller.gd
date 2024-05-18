# Logic controller during the out of combat time when player has full control
# over the party. Should be created by BaseLevel with all public properties
# set.

class_name ExplorationController
extends Node3D

var di = DI.new(self)

@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)
@onready var _ability_resolver: AbilityResolver = di.inject(AbilityResolver)

var _projection_mat = preload("res://materials/terrain_projections.tres")

var _controls: NodeSlot = NodeSlot.new(self, "Controls")

# Dict<GameCharacter, AbilityRequest> which have desired position set and the
# controller should handle pathfinding and movement to that position. Since the
# target's position may change  over time (target character moving), we need to
# handle it in process. Once the target is in reach, we should execute ability
# and remove it from here.
var _requested_abilities: Dictionary = {}

### Lifecycle ###

func _ready() -> void:
	_controlled_characters.action_changed.connect(_on_character_action_changed)
	_controlled_characters.ability_casted.connect(_start_ability_pipeline)
	_controls.mount(FreeMovementControls.new())

func _process(_d) -> void:
	for character in _requested_abilities.keys():
		var request = _requested_abilities[character] as AbilityRequest
		# todo: check vision using raycasting I guess
		if request.can_reach():
			_ability_resolver.execute(request)
			_requested_abilities.erase(character)
		else:
			request.move_to_target()

### Private ###

func _start_ability_pipeline(process: AbilityRequest):
	if process.ability.target_type != Ability.TargetType.SELF:
		var target_select = TargetSelectControls.new();
		_controls.mount(target_select)
		if process.ability.target_type == Ability.TargetType.AOE:
			process.target = await target_select.get_selection_signal(TargetSelectControls.Type.TERRAIN | TargetSelectControls.Type.CHARACTER)
		elif process.ability.target_type == Ability.TargetType.SINGLE:
			process.target = await target_select.get_selection_signal(TargetSelectControls.Type.CHARACTER)
		_controls.mount(FreeMovementControls.new())
	else:
		process.target = AbilityTarget.from_none()

	_requested_abilities[process.caster] = process

func _on_character_action_changed(_character, action):
	# fixme: when goal changes (e.g. another character stopped at that goal
	# first) the decal is not updated...
	if action is CharacterExplorationMovement:
		await action.goal_computed
	_update_goal_vectors()

# Update the _terrain decals for all characters that are currently walking
# somewhere
func _update_goal_vectors():
	var characters = _controlled_characters.get_characters()
	var goals = PackedVector3Array()
	goals.resize(4)
	goals.fill(Vector3(-20, -20, -20))
	for i in range(0, characters.size()):
		var action = characters[i].action
		if action is CharacterExplorationMovement:
			goals[i] = action.goal
	_projection_mat.set_shader_parameter("goal_positions", goals)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action("abort") and not event.echo:
			if _controls.node is TargetSelectControls:
				_controls.mount(FreeMovementControls.new())
