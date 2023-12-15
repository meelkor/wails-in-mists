# Handles character (both PC and NPC) mesh creation, movement and all the
# interactions
class_name CharacterController
extends CharacterBody3D

# Ugly constant, that is already ugly is rusty_fow.rs. GameCharacter
# property instead?
const CHAR_SIGHT_SQ = pow(7, 2)

signal position_changed(new_position: Vector3)
signal action_changed(new_action)
signal clicked(chara: GameCharacter)

# Indicates that something fucky is going on with the path and we may want to
# recompute the path, since e.g. after evasion different path may be better
var recompute_path = false
# Time since the last recomputation, so we don't recompute to often
var recompute_timeout = 0

# Current character's action, which dictates e.g. movement, animation etc.
var action: CharacterAction = CharacterIdle.new()

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

# Current movement speed which increases from 0 over the first few moments of
# the movement.
var current_speed = 0

func _ready():
	_create_character_mesh()
	# todo: doesn't get updated when model changes (e.g. small guy changes into
	# dragon lol)
	var collision_shapes = find_children("CollisionShape3D")
	for shape in collision_shapes:
		shape.reparent(self)

	if character is PlayableCharacter:
		character.selected_changed.connect(func (_c, _s): circle_needs_update = true)

	action.start(self)
	character.state_changed.connect(func (_c): _create_character_mesh())


func _process(delta):
	action.process(self, delta)

# Character movement magic
func _physics_process(delta):
	recompute_timeout += delta
	velocity = Vector3.ZERO

	if action is CharacterWalking:
		# todo: I don't like how the logic is split half here and half in the
		# walking action
		if recompute_path && recompute_timeout > 0.5:
			navigation_agent.target_position = action.goal
			recompute_path = false
			recompute_timeout = 0

		var y_close = abs(action.goal.y - global_position.y) < 1.0
		var diff = abs(action.goal - global_position)
		var xz_close = diff.x < 0.07 and diff.z < 0.07
		if navigation_agent.is_navigation_finished() and y_close and xz_close:
			set_action(CharacterIdle.new())
		else:
			var next_pos = navigation_agent.get_next_path_position()
			var vec = (next_pos - global_position).normalized()
			current_speed = min(action.movement_speed, current_speed + action.movement_speed * delta * 5)
			velocity = vec * current_speed

	$NavigationAgent3D.velocity = velocity

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

# Actually move the character once navigation agent calculates evasion
func _on_navigation_agent_velicity_computed(v: Vector3):
	if action is CharacterWalking:
		# If the agent is avoiding something, better recompute the path next
		# frame
		if (v - velocity).length() > 0.1:
			recompute_path = true

		# Actually update position
		if v != Vector3.ZERO:
			velocity = v

		# Look in our direction
		var final_pos = global_position + velocity
		look_at(final_pos)
		rotation.x = 0
		rotation.z = 0

		move_and_slide()
		# Always stick the character on the ground (tiny little bit below
		# infact so it feels like the ground has some depth)...
		#
		# todo: Maybe should be done per-material basis, so character moves
		# "in" grass, but always on stone floor.
		position.y = $RayCast3D.get_collision_point().y - 0.03
		position_changed.emit(global_position)
	else:
		velocity = Vector3.ZERO

# Always use this method to change character's action
func set_action(new_action: CharacterAction):
	action.end(self)
	new_action.start(self)
	action = new_action
	action_changed.emit(new_action)

# Needs to be called before the node is added into tree, when instantiating
# from code!
func setup(init_character: GameCharacter):
	character = init_character

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
	CharacterMeshBuilder.find_mesh(char_scn).material_override.set_shader_parameter("texture_albedo", char_tex)

	add_child(char_scn)
	char_scn.owner = self
	_character_scene = char_scn
	animation_player = _character_scene.find_child("AnimationPlayer")
	init_animations()
	# todo: ugly, instead somehow copy the old animation player state
	action.start(self)

func init_animations():
	animation_player.get_animation("run").loop_mode = Animation.LOOP_LINEAR
	animation_player.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
	animation_player.get_animation("idle_combat").loop_mode = Animation.LOOP_LINEAR
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

func get_position_on_screen() -> Vector2:
	var camera = get_viewport().get_camera_3d()
	return camera.unproject_position(global_position)

func walk_to(pos: Vector3):
	set_action(CharacterWalking.new(pos))
