## Node which should be created by level during the combat. Takes care of
## character movement, actions etc. during the player's turn.
##
## Note that once this node is added to the tree it starts progressing the
## combat by itself.
class_name CombatController
extends Node3D

var di = DI.new(self)

@onready var _terrain: TerrainWrapper = di.inject(TerrainWrapper)
@onready var _combat: Combat = di.inject(Combat)
@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)

## Node slot for node which handles all mouse inputs and may change based on
## the combat's state
var _controls: NodeSlot = NodeSlot.new(self, "Controls")

### Lifecycle ###

func _ready() -> void:
	_start_combat_turn()
	_controlled_characters.ability_casted.connect(_start_ability_pipeline)


func _process(_delta: float) -> void:
	# Maybe this all should be in combat class??
	if not _combat.is_free():
		_controls.clear()
		var chara = _combat.get_active_character()
		var action = chara.action
		if action is CharacterCombatMovement and chara is PlayableCharacter:
			_combat.state.steps -= action.moved_last_frame
			var available = _combat.get_available_steps()
			if _combat.state.steps <= 0:
				if available > 0:
					_combat.use_action_for_steps()
				else:
					_combat.update_combat_action(chara)
			var projected_path = PackedVector3Array([chara.position])
			projected_path.append_array(action.path)
			_terrain.project_path_to_terrain(projected_path, available, action.moved)
		else:
			_terrain.project_path_to_terrain(PackedVector3Array())
	elif _combat.get_active_character() is PlayableCharacter:
		_controls.get_or_new(CombatFreeControls)


### Private ###
func _start_ability_pipeline(process: AbilityRequest):
	if process.ability.target_type != Ability.TargetType.SELF:
		var target_select = TargetSelectControls.new();
		_controls.mount(target_select)
		if process.ability.target_type == Ability.TargetType.AOE:
			process.target = await target_select.get_selection_signal(TargetSelectControls.Type.TERRAIN | TargetSelectControls.Type.CHARACTER)
		elif process.ability.target_type == Ability.TargetType.SINGLE:
			process.target = await target_select.get_selection_signal(TargetSelectControls.Type.CHARACTER)
		_controls.mount(CombatFreeControls.new())
	else:
		process.target = AbilityTarget.from_none()
	# Handle process
	# too far: show message and retry


## Run logic related to combat turn, setting the active character's action,
## running AI if NPC etc.
##
## Maybe move this into combat???
func _start_combat_turn() -> void:
	var character = _combat.get_active_character()
	global.message_log().system("%s's turn" % character.name)
	_combat.state.turn_actions = Ruleset.calculate_turns(character)
	# todo: implement some animated move_to (ease_to) and use that instead
	get_viewport().get_camera_3d().move_to(character.position)
	for chara in _combat.get_participants():
		_combat.update_combat_action(chara)
	# todo: this signal should be probably "turn end requested" and turn end
	# should be handled afterward
	await _combat.progressed
	if _combat.active and is_inside_tree():
		_start_combat_turn()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		# this should be handled in controls!
		if event.is_action("abort") and not event.echo:
			if _controls.node is TargetSelectControls:
				_controls.mount(FreeMovementControls.new())
		elif event.is_action("end_turn") and not event.echo:
			_combat.end_turn()


# func _start_ability_pipeline(process: AbilityRequest):
# 	if process.ability.target_type != Ability.TargetType.SELF:
# 		var target_select = TargetSelectControls.new();
# 		_controls.mount(target_select)
# 		if process.ability.target_type == Ability.TargetType.AOE:
# 			process.target = await target_select.get_selection_signal(TargetSelectControls.Type.TERRAIN | TargetSelectControls.Type.CHARACTER)
# 		elif process.ability.target_type == Ability.TargetType.SINGLE:
# 			process.target = await target_select.get_selection_signal(TargetSelectControls.Type.CHARACTER)
# 		_controls.mount(FreeMovementControls.new())
# 	else:
# 		process.target = AbilityTarget.from_none()

# 	_requested_abilities[process.caster] = process
