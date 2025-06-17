## Logic controller during the out of combat time when player has full control
## over the party. Should be created by BaseLevel with all public properties
## set.
class_name ExplorationController
extends Node3D

const PROJECT_MATERIAL = preload("res://materials/terrain_projections.tres")

var di := DI.new(self)

@onready var _base_level := di.inject(BaseLevel) as BaseLevel
@onready var _controlled_characters := di.inject(ControlledCharacters) as ControlledCharacters
@onready var _ability_resolver := di.inject(AbilityResolver) as AbilityResolver
@onready var _level_gui := di.inject(LevelGui) as LevelGui

@onready var _circle_container := $Circles

var _controls: NodeSlot = NodeSlot.new(self, "Controls")

## Dict<GameCharacter, AbilityRequest> which have desired position set and the
## controller should handle pathfinding and movement to that position. Since
## the target's position may change  over time (target character moving), we
## need to handle it in process. Once the target is in reach, we should execute
## ability and remove it from here.
var _requested_abilities: Dictionary[GameCharacter, AbilityRequest] = {}


func _ready() -> void:
	_controlled_characters.action_changed_observer.changed.connect(_update_goal_vectors)
	_controlled_characters.ability_casted.connect(_start_ability_pipeline)
	_controlled_characters.selected_changed.connect(_update_ability_caster_bar)
	_base_level.cutscene_changed.connect(_on_cutscene_changed)
	_controls.mount(FreeMovementControls.new())
	_update_goal_vectors()
	_update_ability_caster_bar()


func _process(_d: float) -> void:
	for character: GameCharacter in _requested_abilities.keys():
		var request: AbilityRequest = _requested_abilities[character]
		# make sure character's action was't replaced (e.g. clicked to go
		# somewhere else).
		#
		# todo: Maybe the "movement to reach the ability target" should be
		# action of its own so we do not need to handle it here and replacing
		# the action would cancel the ability request without any extra step.
		# Or even property on the existing exploration movement action. If has
		# ability, do not display target circle. And then just connect to some
		# signal "reached" here.
		if not request.movement_action or character.action == request.movement_action:
			if request.can_reach():
				_requested_abilities.erase(character)
				var execution := _ability_resolver.execute(request)
				await execution.completed
				character.action = CharacterIdle.new()
			else:
				request.move_to_target()
		else:
			_requested_abilities.erase(character)


func _update_ability_caster_bar() -> void:
	var selected_charas := _controlled_characters.get_selected()
	if selected_charas.size() == 1:
		_level_gui.toggle_ability_caster_bar(selected_charas[0])
	else:
		_level_gui.toggle_ability_caster_bar()


func _start_ability_pipeline(request: AbilityRequest) -> void:
	if not request.caster.is_free():
		return

	_requested_abilities.erase(request.caster)

	var target_select: TargetSelectControls = _controls.mount(TargetSelectControls.new())
	request.target = await target_select.select_for_ability(request)
	_controls.get_or_new(FreeMovementControls)

	if request.target:
		_requested_abilities[request.caster] = request


## Update the _terrain decals for all characters that are currently walking
## somewhere
func _update_goal_vectors() -> void:
	# todo: is it expected that even after removal from tree we are still
	# catching some changed signals?
	if not is_inside_tree():
		return
	# wait for navmesh to update, action to start and goal position to be
	# calculated... why three frames and not two? dunno.
	#
	# todo: listen to navigation_agent.path_changed signal and update goal
	# circle then
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var characters := _controlled_characters.get_characters()
	var actions := characters.map(func (character: PlayableCharacter) -> CharacterAction: return character.action)
	var movements := actions.filter(func (a: CharacterAction) -> bool: return a is CharacterExplorationMovement)

	Utils.Nodes.clear_children(_circle_container)
	var GoalCircle := preload("res://lib/exploration/goal_circle.tscn")

	for i in range(0, movements.size()):
		var circle := GoalCircle.instantiate() as Node3D
		var action: CharacterExplorationMovement = movements[i]
		circle.position = action.goal
		_circle_container.add_child(circle)


## Disable controls while in cutscene
func _on_cutscene_changed(cutscene_active: bool) -> void:
	if cutscene_active:
		_controls.clear()
	else:
		_controls.mount(FreeMovementControls.new())
