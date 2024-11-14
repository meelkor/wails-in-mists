## Handles character (both PC and NPC) mesh creation, movement and all the
## interactions
class_name CharacterController
extends CharacterBody3D

var di := DI.new(self)

@onready var controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)

## Ugly constant, that is already ugly is rusty_fow.rs. GameCharacter
## property instead?
const CHAR_SIGHT_SQ = pow(7, 2)

var ability_effect_slot: NodeSlot = NodeSlot.new(self, "AbilityEffect")

## Character we are controlling. Needs to be set by calling the setup method
## before adding the node the tree to function correctly
var character: GameCharacter

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var sight_area := $SightArea as Area3D

## Reference to the character scene, which contains the main character mesh and
## all the appendables. Completely removed and recreated when character's
## visuals change and thus can't be @onready hardcoded
var _character_scene: Node3D
var animation_player: AnimationPlayer


func _ready() -> void:
	_create_character_mesh()
	# todo: doesn't get updated when model changes (e.g. small guy changes into
	# dragon lol)
	var collision_shapes := find_children("CollisionShape3D")
	for shape: CollisionShape3D in collision_shapes:
		if not shape.get_parent() is PhysicalBone3D:
			shape.reparent(self)

	global_position = character.position
	character.action.start(self)
	character.equipment.changed.connect(func () -> void: _create_character_mesh())
	character.position_changed.connect(_update_pos_if_not_same)
	character.before_action_changed.connect(_apply_new_action)


func _process(delta: float) -> void:
	character.action.process(self, delta)


## Character movement magic
func _physics_process(_delta: float) -> void:
	velocity = Vector3.ZERO
	var act := character.action

	var movement := act as CharacterMovement
	if movement:
		if movement.is_navigation_finished(self):
			movement.goal_reached.emit()
			character.action = movement.get_next_action(self)
		else:
			var vec := movement.get_velocity(self)
			velocity = vec * movement.movement_speed

	# Sometimes avoidance is used and sometimes not, so we need to support both
	if navigation_agent.avoidance_enabled:
		navigation_agent.velocity = velocity
	else:
		_apply_final_velocity(velocity)


func _look_in_velocity_direction() -> void:
	# Look in our direction
	var final_pos := global_position + velocity
	look_at(final_pos)
	rotation.x = 0
	rotation.z = 0


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
	var action := character.action as CharacterMovement
	if action:
		# Actually update position
		if v != Vector3.ZERO:
			velocity = v

		if action.max_length > 0:
			velocity.limit_length(action.max_length - action.moved)

		var pos_before := global_position
		move_and_slide()
		_look_in_velocity_direction()

		# Always stick the character on the ground (tiny little bit below
		# infact so it feels like the ground has some depth)...
		#
		# todo: Maybe should be done per-material basis, so character moves
		# "in" grass, but always on stone floor.
		position.y = ($RayCast3D as RayCast3D).get_collision_point().y - 0.03

		character.position = global_position
		action.moved_last_frame = global_position.distance_to(pos_before)
		action.moved += action.moved_last_frame
	else:
		velocity = Vector3.ZERO


## Method which listens to the character resource's action and applies it to
## this controller.
func _apply_new_action(new_action: CharacterAction) -> void:
	var old_action := character.action
	old_action.end(self)
	new_action.start(self)


## Create character mesh with all its equipment etc according to the current
## state of the GameCharacter instance
func _create_character_mesh() -> void:
	if _character_scene:
		remove_child(_character_scene)

	var char_scn := CharacterMeshBuilder.load_human_model(character)
	var skeleton := char_scn.find_child("Skeleton3D") as Skeleton3D
	if character.hair:
		skeleton.add_child(CharacterMeshBuilder.build_hair(character))
	for node in CharacterMeshBuilder.build_equipment_models(character):
		skeleton.add_child(node)
		node.owner = skeleton
		node.reparent(skeleton)
	var char_tex := CharacterMeshBuilder.build_character_texture(character)
	var char_mesh_inst := CharacterMeshBuilder.find_mesh_instance(char_scn)
	var material := char_mesh_inst.material_override as ShaderMaterial
	material.set_shader_parameter("texture_albedo", char_tex)
	add_child(char_scn)
	char_scn.owner = self
	_character_scene = char_scn
	animation_player = _character_scene.find_child("AnimationPlayer")
	init_animations()

	# Normalize physical bones for ragdolls
	var bones := skeleton.find_children("", "PhysicalBone3D")
	for bone: PhysicalBone3D in bones:
		bone.collision_mask = 0b00100
		bone.collision_layer = 0b10000

	# todo: ugly, instead somehow copy the old animation player state
	character.action.start(self)


func init_animations() -> void:
	animation_player.get_animation("run").loop_mode = Animation.LOOP_LINEAR
	animation_player.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
	animation_player.get_animation("idle_combat").loop_mode = Animation.LOOP_LINEAR
	animation_player.animation_set_next("ready_weapon", "idle_combat")
	animation_player.set_blend_time("idle", "run", 0.2)
	animation_player.set_blend_time("run", "idle", 0.2)
	animation_player.set_blend_time("idle", "ready_weapon", 0.15)
	animation_player.set_blend_time("run", "ready_weapon", 0.5)
	animation_player.set_blend_time("ready_weapon", "idle_combat", 0.05)
	# should be combat_walk once it exists
	animation_player.set_blend_time("run", "idle_combat", 0.25)
	animation_player.set_blend_time("idle_combat", "run", 0.2)
