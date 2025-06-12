## Handles character (both PC and NPC) mesh creation, movement and all the
## interactions.
##
## By itself isn't all that aware of the game's mechanics (combat etc) and the
## current animation etc. is all controlled by current CharacterAction, which
## then gives this node a command, what to do.
class_name CharacterController
extends CharacterBody3D

## Speed how quickly can blend of movement animations move
const BLEND_CHANGE_DURATION := 0.35

## Ugly constant, that is already ugly is rusty_fow.rs. GameCharacter
## property instead?
const CHAR_SIGHT_SQ = pow(7, 2)

const D20Projection = preload("res://gui/d20/d_20_projection.gd")

var di := DI.new(self, {
	CharacterController: ^"./",
})

@onready var _level_camera := di.inject(LevelCamera) as LevelCamera
@onready var _base_level: BaseLevel = di.inject(BaseLevel)
@onready var _combat: Combat = di.inject(Combat)

## Character we are controlling. Needs to be set before adding the node the
## tree to function correctly
var character: GameCharacter

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var sight_area := $SightArea as Area3D
@onready var reach_area := $ReachArea as Area3D

@onready var _reach_area_shape := $ReachArea/ReachAreaShape as CollisionShape3D
@onready var _overhead_ui := $OverheadUi as VBoxContainer

## Reference to the character scene, which contains the main character mesh and
## all the appendables. Completely removed and recreated when character's
## visuals change and thus can't be @onready hardcoded
var character_scene: CharacterScene

@onready var interaction_area := $InteractionReach as Area3D

signal _one_shot_ended()

signal _one_shot_changed(new_state: String)

var _equipment_models: CharacterMeshBuilder.EquipmentModels

## Computed movement vector befor avoidance
var _orig_movement: Vector3 = Vector3.ZERO
## Frame delta stored so the avoidance callback can use it
var _last_physics_delta: float

## Flag deciding to which bone the weapon should be attached
var _weapon_drawn: bool = false

## Whether ragdoll physics simulation is on since I haven't found a way to read
## it from the simulator
var _ragdoll_on: bool = false

## Simply set character's animation to one of the predefned state animations
func update_animation(state: AnimationState) -> void:
	if character_scene:
		character_scene.animation_tree["parameters/State/transition_request"] = AnimationState.find_key(state)


## Run one of "well known" one-shot animations that all character scenes are
## expected to support. This method should be primarily called from ability
## visuals scripts.
func fire_animation(animation: OneShotAnimation) -> void:
	var animation_name := OneShotAnimation.find_key(animation) as String
	if character_scene:
		character_scene.animation_tree.set("parameters/OneShotState/transition_request", animation_name)
		character_scene.animation_tree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func abort_animation() -> void:
	character_scene.animation_tree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)


## Wait for given signal with additional timeout in case the animation doesn't
## fire it for whatever reason, so the logic doesn't get stuck.
func wait_for_animation_signal(sig: Signal, timeout: float = 50) -> void:
	var to := get_tree().create_timer(5)
	var merge := SignalMerge.new(sig, to.timeout)
	await merge.any


## Update equipment's attachment's bones based on whether combat is active
func update_equipment_attachments() -> void:
	for item in _equipment_models.attachments:
		var att := _equipment_models.attachments[item]
		att.bone_name = item.combat_bone if _weapon_drawn else item.free_bone
		var model := att.get_child(0) as Node3D
		# todo: how to properly store the offsets? per bone? per item? should
		# the info about bones and offsets be in some separate resource so many
		# weapons may share the same configuration? <- yes
		if att.bone_name == AttachableBone.PELVIS_L:
			model.position = Vector3(-0.091, 0.234, 0.082)
			# todo: find a nice way to copy rotation from godot editor so I
			# don't need to type and convert manually
			model.rotation = Vector3(deg_to_rad(11.3), deg_to_rad(121.0), deg_to_rad(142.3))
		if att.bone_name == AttachableBone.HAND_R:
			model.position = Vector3(0, 0.1, 0.05)
			model.rotation = Vector3(-PI / 2., 0, 0)


## Unless already drawn, run the draw weapon animation and update bones. Can be
## awaited to wait for the weapon to be ready.
func draw_weapon() -> void:
	if not _weapon_drawn:
		_weapon_drawn = true
		fire_animation(OneShotAnimation.READY_WEAPON)
		await wait_for_animation_signal(character_scene.weapon_changed)
		update_equipment_attachments()
		await wait_for_animation_signal(character_scene.animation_tree.animation_finished)


## Unless already drawn, sheath weapon updating its bones. Can be awaited to
## wait for the weapon to be sheathed.
func sheath_weapon() -> void:
	if _weapon_drawn:
		_weapon_drawn = false
		fire_animation(OneShotAnimation.READY_WEAPON)
		await wait_for_animation_signal(character_scene.weapon_changed)
		update_equipment_attachments()
		await wait_for_animation_signal(character_scene.animation_tree.animation_finished)


func show_headline_roll(roll_result: Dice.Result, source_name: String) -> void:
	var row := HBoxContainer.new()
	var d20proj := preload("res://gui/d20/d_20_projection.tscn").instantiate() as D20Projection
	d20proj.roll_result = roll_result
	row.add_child(d20proj)
	var label := Label.new()
	label.text = source_name
	label.theme = preload("res://resources/styles/overhead_text.tres")
	row.add_child(label)
	row.modulate.a = 0.
	_overhead_ui.add_child(row)
	var tween_pre := create_tween()
	tween_pre.tween_property(row, "modulate:a", 1., 0.3)
	tween_pre.set_ignore_time_scale(true)
	await get_tree().create_timer(1.5).timeout
	var tween_post := create_tween()
	tween_post.tween_property(row, "modulate:a", 0., 0.5)
	tween_post.tween_callback(row.queue_free)
	tween_post.set_ignore_time_scale(true)


## Show given text for given duration above character's head. Used primarily
## for saying something outside blocking dialogue.
func show_headline_text(text: String, duration: float) -> void:
	var label := Label.new()
	label.text = text
	label.label_settings = preload("res://resources/styles/overworld_dialogue_text.tres")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.material = preload("res://materials/noise_text/noise_text.tres")
	# todo: generalize fade effects since this logic is now in multiple nodes
	label.visible = false
	_overhead_ui.add_child(label)
	_fade_in(label)
	await global.wait(duration)
	await _fade_out(label)
	_overhead_ui.remove_child(label)
	label.queue_free()


## Fade out given node to transparent and then hide it
func _fade_out(node: Control) -> void:
	if node.visible:
		var tween := create_tween()
		tween.set_ignore_time_scale(true)
		tween.tween_property(node, "modulate", Color(1, 0.5, 0.75, 0), 0.25)
		await tween.finished
		node.visible = false


## Make node visible and fade it in from transparent
func _fade_in(node: Control) -> void:
	if not node.visible:
		node.modulate = Color(1, 0.5, 0.75, 0)
		node.visible = true
		var tween := create_tween()
		tween.set_ignore_time_scale(true)
		tween.tween_property(node, "modulate", Color(1, 1, 1, 1), 0.25)
		await tween.finished


## Enable ragdoll but keep the controller active.
func down_character(source: Vector3) -> void:
	# todo: or use rigged animation for this?
	_activate_ragdoll((global_position - source).normalized() * 1.5)


## Enable ragdoll and replace controller with lootable corpse
func kill_character(src: Vector3) -> void:
	_activate_ragdoll((global_position - src).normalized() * 5.5)
	var lootable_mesh := preload("res://lib/level/lootable_mesh.tscn").instantiate() as LootableMesh
	lootable_mesh.lootable = Lootable.new()
	# todo: fill lootable according to npc's loot_table / gear
	var orig_transform := global_transform
	lootable_mesh.global_transform = orig_transform
	var skelly := character_scene.skeleton
	skelly.transform = Transform3D.IDENTITY
	skelly.get_parent().remove_child(skelly)
	lootable_mesh.add_child(skelly)
	skelly.propagate_call("set", ["owner", lootable_mesh])
	# Addition of lootable into level needs to happen after the children are
	# all ready, since it connects on ready
	_base_level.add_child(lootable_mesh)
	lootable_mesh.owner = _base_level
	# Wait for eventual text to disappear from character's head position.
	#
	# todo: introduce some "text changed" signal a wait for it to actually
	# disapper
	await get_tree().create_timer(2).timeout
	get_parent().remove_child(self)
	self.queue_free()


## todo: implement animated version to use in ability visuals etc
func look_at_standing(target: Vector3) -> void:
	look_at(target)
	rotation.x = 0
	rotation.z = 0


func _ready() -> void:
	_create_character_mesh()
	character_scene.collision_shape.reparent(self)
	_reach_area_shape.shape = SphereShape3D.new()
	global_position = character.position
	character._controller = self
	character.equipment.changed.connect(func () -> void: _create_character_mesh())
	character.changed.connect(_update_areas)
	character.position_changed.connect(_update_pos_if_not_same)
	character.action_changed.connect(_stop_old_action)
	reach_area.body_exited.connect(_on_reach_exit)
	_update_areas()


func _exit_tree() -> void:
	if character._controller == self:
		character._controller = null


func _process(delta: float) -> void:
	character.action.process(self, delta)
	# find out whether this should be in process or physics process somehow
	var anchor_3d := global_position + Vector3.UP * character_scene.body.get_aabb().size.y
	var anchor_2d := _level_camera.unproject_position(anchor_3d)
	_overhead_ui.position = anchor_2d + _overhead_ui.size * Vector2(-0.5, -1.)


## Character movement magic
func _physics_process(delta: float) -> void:
	_last_physics_delta = delta
	velocity = Vector3.ZERO
	var act := character.action

	var movement := act as CharacterMovement
	# todo: the whole movement thing is retarded that half of the logic is
	# there and half is here, rewrite...p
	var speed := character.combat_movement_speed if act is CharacterCombatMovement else character.free_movement_speed
	if movement:
		if movement.is_navigation_finished(self):
			movement.goal_reached.emit()
			character.action = movement.get_next_action(self)
		else:
			var vec := movement.get_velocity(self)
			velocity = vec * speed

	# Sometimes avoidance is used and sometimes not, so we need to support both
	_orig_movement = velocity
	if navigation_agent.avoidance_enabled:
		navigation_agent.velocity = velocity
	else:
		_apply_final_velocity(velocity)


func _look_in_direction(direction: Vector3) -> void:
	# Look in our direction
	var final_pos := global_position + direction
	if global_position != final_pos:
		look_at(final_pos)
	rotation.x = 0
	rotation.z = 0


## Update areas (reach etc) based on character properties
func _update_areas() -> void:
	var reach := character.get_aoo_reach()
	if reach > 0:
		# todo: decide wheter reach should be really on wpn or the AoO modifier
		# instead (probably option b is correct)
		(_reach_area_shape.shape as SphereShape3D).radius = reach
		_reach_area_shape.disabled = false
	else:
		_reach_area_shape.disabled = true


## Emit combat trigger whenever character moves outside this character's reach
## if combat active but this character is not active
func _on_reach_exit(body: Node3D) -> void:
	var leaving_ctrl := body as CharacterController
	if leaving_ctrl and leaving_ctrl != self and _combat.active and _combat.get_active_character() != character:
		var trigger := LeftReachTrigger.new()
		trigger.leaving_character = leaving_ctrl.character
		_combat.emit_trigger(trigger, character)


func _activate_ragdoll(physics_velocity: Vector3 = global_transform.basis.z) -> void:
	_ragdoll_on = true
	character_scene.animation_tree.active = false
	for bone: PhysicalBone3D in character_scene.simulator.get_children():
		if not bone.is_in_group("leg_bone"):
			PhysicsServer3D.body_set_state(bone.get_rid(), PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, physics_velocity)
	character_scene.simulator.physical_bones_start_simulation()


## Accept character mouse selection
func _input_event(_camera: Camera3D, e: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	var btn := e as InputEventMouseButton
	if btn and btn.button_index == MOUSE_BUTTON_LEFT and e.is_released():
		character.clicked.emit(GameCharacter.InteractionType.SELECT)


func _mouse_enter() -> void:
	character.hovered = true


func _mouse_exit() -> void:
	character.hovered = false


func _update_pos_if_not_same(pos: Vector3) -> void:
	if pos != global_position:
		global_position = pos


## Actually move the character once navigation agent calculates evasion (if
## enabled)
func _apply_final_velocity(v: Vector3) -> void:
	var moved_len := 0.
	var action := character.action as CharacterMovement
	if action:
		# Actually update position
		if v != Vector3.ZERO:
			velocity = v

		if action.max_length > 0:
			velocity.limit_length(action.max_length - action.moved)

		var pos_before := global_position
		move_and_slide()
		_look_in_direction(_orig_movement)

		# Always stick the character on the ground (tiny little bit below
		# infact so it feels like the ground has some depth)...
		#
		# todo: Maybe should be done per-material basis, so character moves
		# "in" grass, but always on stone floor.
		position.y = ($RayCast3D as RayCast3D).get_collision_point().y - 0.03

		character.position = global_position
		moved_len = global_position.distance_to(pos_before)
		action.moved_last_frame += moved_len
		action.moved += action.moved_last_frame
	else:
		velocity = Vector3.ZERO

	var curr_speed: float = max(0.4, moved_len / _last_physics_delta) if action else 0
	var current_blend := character_scene.animation_tree["parameters/RunBlend/blend_amount"] as float
	var current_combat_blend := character_scene.animation_tree["parameters/CombatWalkBlend/blend_amount"] as float
	character_scene.animation_tree["parameters/RunBlend/blend_amount"] = move_toward(current_blend, curr_speed / character.free_movement_speed, _last_physics_delta / BLEND_CHANGE_DURATION)
	character_scene.animation_tree["parameters/CombatWalkBlend/blend_amount"] = move_toward(current_combat_blend, curr_speed / character.combat_movement_speed, _last_physics_delta / 0.1)


## Method which listens to the character resource's action and applies it to
## this controller.
func _stop_old_action(old_action: CharacterAction, _new_action: CharacterAction) -> void:
	old_action.end(self)
	_base_level.enqueue_character_action(character)


## Create character mesh with all its equipment etc according to the current
## state of the GameCharacter instance
##
## todo: introduce some CharacterVisuals class that handles defining required
## inputs (e.g. hair color) and also creates the final fesh. Add it as property
## to GameCharacter as different character visuals (human vs dog) will require
## different setup.
func _create_character_mesh() -> void:
	if character_scene:
		remove_child(character_scene)

	character_scene = CharacterMeshBuilder.load_human_model(character)
	var eyes_material := preload("res://materials/eyes_material.tres").duplicate() as StandardMaterial3D
	# todo: color should be read from CaracterVisuals once exists
	eyes_material.albedo_color = Color.AQUA
	character_scene.eyes.material_override = eyes_material
	if character.hair:
		character_scene.skeleton.add_child(CharacterMeshBuilder.build_hair(character))
	_equipment_models = CharacterMeshBuilder.build_equipment_models(character)
	for node in _equipment_models.get_all_nodes():
		node.owner = null
		if node.get_parent():
			node.reparent(character_scene.skeleton, false)
		else:
			character_scene.skeleton.add_child(node)
		node.owner = character_scene.skeleton
	update_equipment_attachments()
	var char_tex := CharacterMeshBuilder.build_character_texture(character)
	var material := character_scene.body.material_override as ShaderMaterial
	material.set_shader_parameter("texture_albedo", char_tex)
	add_child(character_scene)
	character_scene.owner = self
	character_scene = character_scene

	# Normalize physical bones for ragdolls
	var bones := character_scene.skeleton.find_children("", "PhysicalBone3D")
	for bone: PhysicalBone3D in bones:
		bone.collision_mask = 0b00100
		bone.collision_layer = 0b10000

	# todo: ugly, instead somehow copy the old animation player state
	character.action.start(self)


func _to_string() -> String:
	return "<CharacterController:%s#%s>" % [character.name, get_instance_id()]


enum AnimationState {
	IDLE,
	COMBAT,
}

## Well known animations that each character scene's AnimationTree should
## contain to support all kind of abilities. Those one shot animations are then
## set using OneShotState transition node and fired using Ability oneshot node.
##
## :see fire_animation:
enum OneShotAnimation {
	READY_WEAPON,
	MELEE_1H_ATTACK,
}
