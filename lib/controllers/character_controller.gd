# Handles character (both PC and NPC) mesh creation, movement and all the
# interactions
class_name CharacterController
extends CharacterBody3D

# Ugly constant, that is already ugly is rusty_fow.rs. GameCharacter
# property instead?
const CHAR_SIGHT_SQ = pow(7, 2)

signal clicked(chara: GameCharacter)

var ability_effect_slot: NodeSlot = NodeSlot.new(self, "AbilityEffect")

# Run the circle state logic on next frame if true.
#
# TODO: consider moving this out of this class now that this class serves for
# NPCs as well
var circle_needs_update = false
var hovered: bool = false:
	get:
		return hovered
	set(v):
		hovered = v
		circle_needs_update = true

# Character we are controlling. Needs to be set by calling the setup method
# before adding the node the tree to function correctly
var character: GameCharacter

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

# Reference to the character scene, which contains the main character mesh and
# all the appendables. Completely removed and recreated when character's
# visuals change and thus can't be @onready hardcoded
var _character_scene: Node3D
var animation_player: AnimationPlayer

func _ready():
	_create_character_mesh()
	# todo: doesn't get updated when model changes (e.g. small guy changes into
	# dragon lol)
	var collision_shapes = find_children("CollisionShape3D")
	for shape in collision_shapes:
		shape.reparent(self)

	if character is PlayableCharacter:
		character.selected_changed.connect(func (_c, _s): circle_needs_update = true)

	global_position = character.position
	character.action.start(self)
	character.state_changed.connect(func (_c): _create_character_mesh())
	character.position_changed.connect(_update_pos_if_not_same)
	character.before_action_changed.connect(_apply_new_action)

func _process(delta):
	character.action.process(self, delta)

# Character movement magic
func _physics_process(_delta):
	velocity = Vector3.ZERO
	var act = character.action

	if act is CharacterMovement:
		if act.is_navigation_finished(self):
			character.action = act.get_next_action(self)
		else:
			var vec = act.get_velocity(self)
			velocity = vec * act.movement_speed

	# Sometimes avoidance is used and sometimes not, so we need to support both
	if navigation_agent.avoidance_enabled:
		$NavigationAgent3D.velocity = velocity
	else:
		_apply_final_velocity(velocity)

func _look_in_velocity_direction():
	# Look in our direction
	var final_pos = global_position + velocity
	look_at(final_pos)
	rotation.x = 0
	rotation.z = 0

# Accept character mouse selection
func _input_event(_camera, e, _position, _normal, _shape_idx):
	if e is InputEventMouseButton && e.is_released():
		clicked.emit(character)

# TODO: signal
func _mouse_enter():
	hovered = true

# TODO: signal
func _mouse_exit():
	hovered = false

func _update_pos_if_not_same(pos: Vector3):
	if pos != global_position:
		global_position = pos

# Actually move the character once navigation agent calculates evasion (if
# enabled)
func _apply_final_velocity(v: Vector3):
	var action = character.action
	if action is CharacterMovement:
		# Actually update position
		if v != Vector3.ZERO:
			velocity = v

		if action.max_length > 0:
			velocity.limit_length(action.max_length - action.moved)

		var pos_before = global_position
		move_and_slide()
		_look_in_velocity_direction()

		# Always stick the character on the ground (tiny little bit below
		# infact so it feels like the ground has some depth)...
		#
		# todo: Maybe should be done per-material basis, so character moves
		# "in" grass, but always on stone floor.
		position.y = $RayCast3D.get_collision_point().y - 0.03

		character.position = global_position
		action.moved_last_frame = global_position.distance_to(pos_before)
		action.moved += action.moved_last_frame
	else:
		velocity = Vector3.ZERO

# Method which listens to the character resource's action and applies it to
# this controller.
func _apply_new_action(new_action: CharacterAction):
	var old_action = character.action
	old_action.end(self)
	new_action.start(self)

# Create character mesh with all its equipment etc according to the current
# state of the GameCharacter instance
func _create_character_mesh():
	if _character_scene:
		remove_child(_character_scene)

	var char_scn = CharacterMeshBuilder.load_human_model(character)
	var skeleton = char_scn.find_child("Skeleton3D") as Skeleton3D
	if character.hair:
		skeleton.add_child(CharacterMeshBuilder.build_hair(character))
	for node in CharacterMeshBuilder.build_equipment_models(character):
		skeleton.add_child(node)
		node.owner = skeleton
		node.reparent(skeleton)
	var char_tex = CharacterMeshBuilder.build_character_texture(character)
	var char_mesh_inst = CharacterMeshBuilder.find_mesh_instance(char_scn)
	char_mesh_inst.mesh.surface_get_material(0).set_shader_parameter("texture_albedo", char_tex)

	# TODO: I hate that we need to create duplicate mesh just to display in
	# with different shader in subviewport. Find alternative?
	var char_mask: MeshInstance3D = char_mesh_inst.duplicate() as MeshInstance3D
	char_mask.layers = 0b100
	# TODO: set different mask color depending on PC/NPC/ENEMY. Maybe introduce
	# some shared materials enum so we don't need to recreate the materials
	# again and again for each character
	char_mask.material_override = preload("res://materials/mask/mask_material.tres")
	char_mesh_inst.get_parent().add_child(char_mask)

	add_child(char_scn)
	char_scn.owner = self
	_character_scene = char_scn
	animation_player = _character_scene.find_child("AnimationPlayer")
	init_animations()
	# todo: ugly, instead somehow copy the old animation player state
	character.action.start(self)

func init_animations():
	animation_player.get_animation("run").loop_mode = Animation.LOOP_LINEAR
	animation_player.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
	animation_player.get_animation("idle_combat").loop_mode = Animation.LOOP_LINEAR
	animation_player.animation_set_next("ready_weapon", "idle_combat")
	animation_player.set_blend_time("idle", "run", 0.2)
	animation_player.set_blend_time("run", "idle", 0.2)
	animation_player.set_blend_time("idle", "ready_weapon", 0.15)
	animation_player.set_blend_time("run", "ready_weapon", 0.5)
	animation_player.set_blend_time("ready_weapon", "idle_combat", 0.05)

func update_selection_circle(enabled: bool, color: Vector3 = Vector3.ZERO, opacity: float = 1.0):
	if (enabled):
		$SelectionCircle.show()
		$SelectionCircle.transparency = 1 - opacity
		$SelectionCircle.set_instance_shader_parameter("circle_color", color)
	else:
		$SelectionCircle.hide()
