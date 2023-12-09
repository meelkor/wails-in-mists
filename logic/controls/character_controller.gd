class_name CharacterController
extends CharacterBody3D

signal position_changed(new_position: Vector3)
signal action_changed(new_action)

var recompute_path = false
var recompute_timeout = 0

var action;

var movement_delta: float = 0;

var last_delta: float = 0;

var circle_needs_update = false
var hovered: bool = false:
	get:
		return hovered
	set(v):
		hovered = v
		circle_needs_update = true

@export var walking_speed = 3 # m/s

# Character we are controlling. Needs to be set by calling the setup method
# before adding the node the tree to function correctly
var character: PlayableCharacter

@onready var navigation_agent = $NavigationAgent3D
@onready var model = $CharacterModel
@onready var player = $CharacterModel/AnimationPlayer as AnimationPlayer

# Local information whether this model is in combat, since while game may be
# in combat mode, character might be too far and not part of it
var in_combat: bool = false

var current_speed = 0

func _ready():
	var collision_shapes = find_children("", "CollisionShape3D")
	for shape in collision_shapes:
		shape.reparent(self)

	init_animations()


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

func _physics_process(delta):
	last_delta = delta
	recompute_timeout += delta
	velocity = Vector3.ZERO

	if action is CharacterWalking:
		if recompute_path && recompute_timeout > 0.5:
			navigation_agent.target_position = action.goal
			recompute_path = false
			recompute_timeout = 0

		if navigation_agent.is_navigation_finished():
			set_action(CharacterIdle.new())
		else:
			var next_pos = navigation_agent.get_next_path_position()
			var vec = (next_pos - global_position).normalized()
			current_speed = min(walking_speed, current_speed + walking_speed * delta * 5)
			movement_delta = current_speed
			velocity = vec * movement_delta

	$NavigationAgent3D.velocity = velocity

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

		# Look in our direction
		var final_pos = global_position + v
		look_at(final_pos)
		rotation.x = 0
		rotation.z = 0

		# Actually update position
#		global_position = global_position.move_toward(final_pos, movement_delta)
		velocity = v + Vector3.DOWN * 9.8 * last_delta
		move_and_slide()
		position_changed.emit(global_position)
	else:
		velocity = Vector3.DOWN * 8 * last_delta
		move_and_slide()

# Always use this method to change character's action
func set_action(new_action: CharacterAction):
	var old_action = action

	if new_action is CharacterWalking:
		player.play.call_deferred("run", -1, 0.75)

		if not old_action is CharacterWalking:
			current_speed = 0

	elif new_action is CharacterIdle:
		player.play.call_deferred("idle")

	action = new_action
	action_changed.emit(new_action)

# Needs to be called before the node is added into tree, when instantiating
# from code!
func setup(init_character: PlayableCharacter, new_model: Node):
	character = init_character
	new_model.name = "CharacterModel"
	add_child(new_model)
	new_model.owner = self

	var char_mesh = new_model.find_child("human_female") as MeshInstance3D
	var characterShader = load("res://shaders/character.tres") as ShaderMaterial
	characterShader.set_shader_parameter("albedo", Color(float(0xE4) / 255, float(0xBC) / 255, float(0xAE) / 255, 1))
	characterShader.set_shader_parameter("texture_albedo", load("res://textures/medium_armor_gray_character_tex.png"))
	char_mesh.mesh.surface_set_material(0, characterShader)

	var skeleton = new_model.find_child("Skeleton3D") as Skeleton3D
	var sword_scene = (load("res://models/short_sword.tscn") as PackedScene).instantiate()

	var hair_scene = (load("res://models/hair1.glb") as PackedScene).instantiate()

	var armor_scene = (load("res://models/medium_armor.glb") as PackedScene).instantiate()
	var armor_meshes = armor_scene.find_children("", "MeshInstance3D") as Array[MeshInstance3D]
	for armor_mesh in armor_meshes:
		skeleton.add_child(armor_mesh)
		armor_mesh.owner = skeleton
		armor_mesh.reparent(skeleton)

	var attachment = BoneAttachment3D.new()
	attachment.bone_name = "weapon_small"
	attachment.add_child(sword_scene)
	skeleton.add_child(attachment)

	var hair_attachment = BoneAttachment3D.new()
	hair_attachment.bone_name = "spine.006"
	hair_attachment.add_child(hair_scene)
	skeleton.add_child(hair_attachment)


func init_animations():
	player.get_animation("run").loop_mode = Animation.LOOP_LINEAR
	player.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
	player.get_animation("idle_combat").loop_mode = Animation.LOOP_LINEAR
	player.set_blend_time("idle", "run", 0.2)
	player.set_blend_time("run", "idle", 0.2)
	player.set_blend_time("idle", "ready_weapon", 0.15)
	player.set_blend_time("run", "ready_weapon", 0.5)
	player.set_blend_time("ready_weapon", "idle_combat", 0.05)
	player.play("idle")

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
	navigation_agent.target_position = pos
	set_action(CharacterWalking.new(navigation_agent.get_final_position()))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		# Hacky event for testing animations
		if event.is_released() && event.keycode == KEY_SPACE:
			if in_combat:
				player.animation_set_next("ready_weapon", "idle")
				player.play("ready_weapon", -1, -1.2, true)
				in_combat = false
			else:
				player.animation_set_next("ready_weapon", "idle_combat")
				player.play("ready_weapon", -1, 1.2)
				in_combat = true
		action = CharacterIdle.new()
		navigation_agent.target_position = position
