## Node which should be created by level during the combat. Takes care of
## character movement, actions etc. during the player's turn.
##
## Note that once this node is added to the tree it starts progressing the
## combat by itself.
class_name CombatController
extends Node3D

var di := DI.new(self)

@onready var _terrain: TerrainWrapper = di.inject(TerrainWrapper)
@onready var _combat: Combat = di.inject(Combat)
@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)
@onready var _ability_resolver: AbilityResolver = di.inject(AbilityResolver)
@onready var _level_camera: LevelCamera = di.inject(LevelCamera)

## Node slot for node which handles all mouse inputs and may change based on
## the combat's state
var _controls: NodeSlot = NodeSlot.new(self, "Controls")

### Lifecycle ###

func _ready() -> void:
	_start_combat_turn()
	_controlled_characters.ability_casted.connect(_run_ability_pipeline)


func _process(_delta: float) -> void:
	# Maybe this all should be in combat class??
	if not _combat.is_free():
		var chara := _combat.get_active_character()
		var action := chara.action
		var movement := action as CharacterCombatMovement
		if movement and chara is PlayableCharacter:
			_combat.state.steps -= movement.moved_last_frame
			# ugly but the movement isn't bound the framerate, move it
			# somewhere else in case another node needs to read is as well.
			movement.moved_last_frame = 0.
			var available := _combat.get_available_steps()
			if _combat.state.steps <= 0:
				if available > 0:
					_combat.use_action_for_steps()
				else:
					_combat.update_combat_action(chara)
			var projected_path := PackedVector3Array([chara.position])
			projected_path.append_array(movement.path)
			_terrain.project_path_to_terrain(projected_path, available, movement.moved)
		else:
			_terrain.project_path_to_terrain(PackedVector3Array())
	# I hate this condition here, but I currently have no way to react to
	# movement end
	elif _combat.get_active_character() is PlayableCharacter and _controls.is_empty():
		_controls.get_or_new(CombatFreeControls)


### Private ###

func _run_ability_pipeline(request: AbilityRequest) -> void:
	if request.ability.target_type != Ability.TargetType.SELF:
		var target_select: TargetSelectControls = _controls.mount(TargetSelectControls.new())
		request.target = await target_select.select_for_ability(request)
		# todo: check vision using raycasting I guess, also the same logic is
		# defined in ExplorationController :/
		if request.target:
			if request.can_reach():
				_combat.state.use_actions(request.ability.required_actions)
				_controls.clear()
				await _ability_resolver.execute(request).completed
				_combat.update_combat_action(request.caster)
			else:
				# todo introduce some system feedback system
				_run_ability_pipeline(request)
		else:
			_controls.get_or_new(CombatFreeControls)
	else:
		request.target = AbilityTarget.from_none()
	# Handle process
	# too far: show message and retry


## Run logic related to combat turn, setting the active character's action,
## running AI if NPC etc.
##
## Maybe move this into combat???
func _start_combat_turn() -> void:
	var character := _combat.get_active_character()
	global.message_log().system("%s's turn" % character.name)
	_combat.state.turn_actions = Ruleset.calculate_turns(character)
	_combat.state.steps = 0
	# todo: implement some animated move_to (ease_to) and use that instead
	_level_camera.move_to(character.position)
	for chara in _combat.get_participants():
		_combat.update_combat_action(chara)
	if character is NpcCharacter:
		_controls.clear()
		# todo: AI behaviour scripts whatever
		await get_tree().create_timer(1).timeout
		global.message_log().dialogue(character.name, Color.BLUE_VIOLET, "*does nothing*")
		_combat.end_turn.call_deferred()
	elif _combat.get_active_character() is PlayableCharacter:
		_controls.get_or_new(CombatFreeControls)
	# todo: this signal should be probably "turn end requested" and turn end
	# should be handled afterward
	await _combat.progressed
	if _combat.active and is_inside_tree():
		_start_combat_turn()
