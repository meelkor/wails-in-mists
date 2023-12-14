class_name CharacterController
extends CharacterBody3D

signal position_changed(new_position: Vector3)
signal action_changed(new_action)

var recompute_path = false
var recompute_timeout = 0

var action = CharacterIdle.new()

var movement_delta: float = 0;

var last_delta: float = 0;

var circle_needs_update = false
var hovered: bool = false:
	get:
		return hovered
	set(v):
		hovered = v
		circle_needs_update = true

@export var walking_speed = 2.8 # m/s

# Character we are controlling. Needs to be set by calling the setup method
# before adding the node the tree to function correctly
var character: PlayableCharacter

@onready var navigation_agent = $NavigationAgent3D

var _character_scene: Node3D
var _animation_player: AnimationPlayer

# Local information whether this character is in combat, since while game may be
# in combat mode, character might be too far and not part of it
var in_combat: bool = false

var current_speed = 0

var desired_y: float = position.y

func _ready():
	var collision_shapes = find_children("CollisionShape3D")
	for shape in collision_shapes:
		shape.reparent(self)

	character.selected_changed.connect(func (_c, _s): circle_needs_update = true)

func _process(_delta):
	if circle_needs_update:
		if character.selected:
			update_selection_circle(true, Vector3(0.094,0.384,0.655), 1.0)
		elif hovered:
			update_selection_circle(true, Vector3(0.239,0.451,0.651), 0.4)
		else:
			update_selection_circle(false)
		circle_needs_update = false

# Character movement magic
func _physics_process(delta):
	last_delta = delta
	recompute_timeout += delta
	velocity = Vector3.ZERO

	if action is CharacterWalking:
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
			var collision_point = $RayCast3D.get_collision_point()
			desired_y = collision_point.y
			next_pos.y = collision_point.y
			var vec = (next_pos - global_position).normalized()
			current_speed = min(walking_speed, current_speed + walking_speed * delta * 5)
			movement_delta = current_speed
			velocity = vec * movement_delta

	$NavigationAgent3D.velocity = velocity

# Accept character mouse selection
func _input_event(_camera, e, _position, _normal, _shape_idx):
	if e is InputEventMouseButton && e.is_released():
		get_parent().select_single(character)

func _mouse_enter():
	hovered = true

func _mouse_exit():
	hovered = false

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
		position.y = desired_y
		position_changed.emit(global_position)
	else:
		velocity = Vector3.ZERO

# Always use this method to change character's action
func set_action(new_action: CharacterAction):
	new_action.start(self)
	action = new_action
	action_changed.emit(new_action)

# Needs to be called before the node is added into tree, when instantiating
# from code!
func setup(init_character: PlayableCharacter):
	character = init_character

	_create_character_mesh()
	character.state_changed.connect(func (_c): _create_character_mesh())

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
	_animation_player = _character_scene.find_child("AnimationPlayer")
	init_animations()

func init_animations():
	_animation_player.get_animation("run").loop_mode = Animation.LOOP_LINEAR
	_animation_player.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
	_animation_player.get_animation("idle_combat").loop_mode = Animation.LOOP_LINEAR
	_animation_player.set_blend_time("idle", "run", 0.2)
	_animation_player.set_blend_time("run", "idle", 0.2)
	_animation_player.set_blend_time("idle", "ready_weapon", 0.15)
	_animation_player.set_blend_time("run", "ready_weapon", 0.5)
	_animation_player.set_blend_time("ready_weapon", "idle_combat", 0.05)
	action.start(self)

func update_selection_circle(enabled: bool, color: Vector3 = Vector3.ZERO, opacity: float = 1.0):
	if (enabled):
		$SelectionCircle.show()
		$SelectionCircle.transparency = 1 - opacity
		var mat: ShaderMaterial = $SelectionCircle.get_active_material(0)
		mat.set_shader_parameter("circle_color", color)
	else:
		$SelectionCircle.hide()

func get_position_on_screen() -> Vector2:
	var camera = get_viewport().get_camera_3d()
	return camera.unproject_position(global_position)

func walk_to(pos: Vector3):
	navigation_agent.target_position = pos
	set_action(CharacterWalking.new(navigation_agent.get_final_position()))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		# Hacky event for testing animations
		if event.is_released() && event.keycode == KEY_SPACE:
			if in_combat:
				_animation_player.animation_set_next("ready_weapon", "idle")
				_animation_player.play("ready_weapon", -1, -1.2, true)
				in_combat = false
			else:
				_animation_player.animation_set_next("ready_weapon", "idle_combat")
				_animation_player.play("ready_weapon", -1, 1.2)
				in_combat = true
		action = CharacterIdle.new()
		navigation_agent.target_position = position
