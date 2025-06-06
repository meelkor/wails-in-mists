## Node which should be created by level during the combat. Takes care of
## character movement, actions etc. during the player's turn.
##
## Note that once this node is added to the tree it starts progressing the
## combat by itself.
class_name CombatController
extends Node3D

var di := DI.new(self)

const CombatFreeControlsScene = preload("res://lib/combat/controls/combat_free_controls.tscn")

@onready var _terrain: Terrain = di.inject(Terrain)
@onready var _combat: Combat = di.inject(Combat)
@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)
@onready var _ability_resolver: AbilityResolver = di.inject(AbilityResolver)
@onready var _level_camera: LevelCamera = di.inject(LevelCamera)
@onready var _level_gui: LevelGui = di.inject(LevelGui)

## Node slot for node which handles all mouse inputs and may change based on
## the combat's state
var _controls: NodeSlot = NodeSlot.new(self, "Controls")

### Lifecycle ###

func _ready() -> void:
	_start_combat_turn()
	_controlled_characters.ability_casted.connect(_run_ability_pipeline)


func _process(_delta: float) -> void:
	# Take care of combat movement. Maybe this all should be in combat class??
	# Actually if I were able to put it into movement action somehow it would
	# be perfect.
	var chara := _combat.get_active_character()
	var movement := chara.action as CharacterCombatMovement
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
				_terrain.project_path_to_terrain([])
		var projected_path := PackedVector3Array([chara.position])
		projected_path.append_array(movement.path)
		_terrain.project_path_to_terrain(projected_path, available, movement.moved, movement.red_highlight - Vector2(movement.moved, movement.moved))
	# I hate this condition here, but I currently have no way to react to
	# movement end
	elif _combat.get_active_character() is PlayableCharacter and _controls.is_empty():
		_controls.get_or_instantiate(CombatFreeControlsScene)


### Private ###

func _run_ability_pipeline(request: AbilityRequest) -> void:
	if not request.caster.is_free() or not request.ability.can_cast_with_attrs(_combat.get_turn_action_dict(request.caster)):
		return
	var target_select: TargetSelectControls = _controls.mount(TargetSelectControls.new())
	request.target = await target_select.select_for_ability(request)
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
		_controls.get_or_instantiate(CombatFreeControlsScene)


## Run logic related to combat turn, setting the active character's action,
## running AI if NPC etc.
##
## Maybe move this into combat???
func _start_combat_turn() -> void:
	_terrain.project_path_to_terrain([])
	var character := _combat.get_active_character()
	global.message_log().system("%s's turn" % character.name)
	_combat.state.turn_actions = Ruleset.calculate_turns(character)
	_combat.state.steps = 0
	await _level_camera.ease_to(character.position)
	for chara in _combat.get_participants():
		_combat.update_combat_action(chara)
	if character is NpcCharacter:
		_level_gui.toggle_ability_caster_bar(null)
		_controls.clear()
		# todo: AI behaviour scripts whatever
		await get_tree().create_timer(1).timeout
		global.message_log().dialogue(character.name, Color.BLUE_VIOLET, "*does nothing*")
		_combat.end_turn.call_deferred()
	elif character is PlayableCharacter:
		_level_gui.toggle_ability_caster_bar(character as PlayableCharacter)
		_controls.get_or_instantiate(CombatFreeControlsScene)
	# todo: this signal should be probably "turn end requested" and turn end
	# should be handled afterward
	await _combat.progressed
	_level_gui.toggle_ability_caster_bar(null)
	if _combat.active and is_inside_tree():
		_start_combat_turn()
