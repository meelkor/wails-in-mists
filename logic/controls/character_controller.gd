class_name CharacterController
extends CharacterBody3D

signal position_changed(new_position: Vector3)
signal action_changed(new_action)

var last_physics_position: Vector3

var action:
	get:
		return action
	set(v):
		if action != v:
			action = v
			action_changed.emit(v)

var circle_needs_update = false
@export var selected: bool = false:
	get:
		return selected
	set(v):
		selected = v
		circle_needs_update = true
var hovered: bool = false:
	get:
		return hovered
	set(v):
		hovered = v
		circle_needs_update = true

@onready var navigation_agent = $NavigationAgent3D
@onready var model = $CharacterModel
@onready var player = $CharacterModel/AnimationPlayer

func _ready():
	var collision_shapes = find_children("", "CollisionShape3D")
	for shape in collision_shapes:
		shape.reparent(self)

	init_animations()
	init_navigation()

func _process(_delta):
	if circle_needs_update:
		if selected:
			update_selection_circle(true, Vector3(0.094,0.384,0.655), 1.0)
		elif hovered:
			update_selection_circle(true, Vector3(0.239,0.451,0.651), 0.4)
		else:
			update_selection_circle(false)
		circle_needs_update = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if action is CharacterWalking:
		if navigation_agent.is_navigation_finished():
			action = null
			player.play("idle")
		else:
			var next_pos = navigation_agent.get_next_path_position()
			var orig = rotation
			if next_pos != orig:
				look_at(next_pos)
			rotation.x = orig.x
			rotation.z = orig.z
			var vec = (next_pos - global_position).normalized()
			var multiplier = 3.5 * delta
			position += vec * multiplier
			move_and_collide(Vector3.DOWN)
			position_changed.emit(position)

func _input_event(_camera, e, _position, _normal, _shape_idx):
	if e is InputEventMouseButton && e.is_released():
		get_parent().select_single(self)

func _mouse_enter():
	hovered = true

func _mouse_exit():
	hovered = false

# Needs to be called before the node is added into tree, when instantiating from
# code!
func setup(model: Node):
	model.name = "CharacterModel"
	add_child(model)
	model.owner = self

func init_animations():
	player.set_blend_time("idle", "walk", 0.2)
	player.set_blend_time("walk", "idle", 0.2)
	for animation_name in player.get_animation_list():
		var animation: Animation = player.get_animation(animation_name)
		animation.loop_mode = Animation.LOOP_LINEAR

	# each character should have idle animation
	player.play("idle")

func init_navigation():
	navigation_agent.target_desired_distance = 0.1
	navigation_agent.path_desired_distance = 0.15

func update_selection_circle(enabled: bool, color: Vector3 = Vector3.ZERO, opacity: float = 1.0):
	if (enabled):
		$SelectionCircle.show()
		$SelectionCircle.transparency = 1 - opacity
		var mat: ShaderMaterial = $SelectionCircle.get_active_material(0)
		mat.set_shader_parameter("circle_color", color)
	else:
		$SelectionCircle.hide()

func get_position_on_screen() -> Vector2:
	var camera: Camera3D = get_node("/root/GameRoot/Level/LevelCamera")
	return camera.unproject_position(global_position)

func walk_to(pos: Vector3):
	action = CharacterWalking.new(pos)
	player.play("walk")
	navigation_agent.target_position = action.goal
