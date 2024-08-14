## Node that makes child mesh interactable, opening looting interface with
## content based on the given lootable resource
class_name LootableMesh
extends Node3D

var di = DI.new(self)

@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)
@onready var _combat: Combat = di.inject(Combat)
@onready var _level_gui: LevelGui = di.inject(LevelGui)

@export var lootable: Lootable

var _mask_meshes: Array[MeshInstance3D]

func _ready() -> void:
	var meshes = find_children("", "MeshInstance3D")
	for mesh in meshes:
		var mask  = mesh.duplicate() as MeshInstance3D
		mask.material_override = preload("res://materials/outline/outline.tres")
		mask.layers = 0b1000;
		mesh.get_parent().add_child(mask)
		mask.visible = false
		_mask_meshes.append(mask)

	var collision_objects = find_children("", "CollisionObject3D")
	for co in collision_objects:
		if co is CollisionObject3D:
			co.mouse_entered.connect(_on_enter)
			co.mouse_exited.connect(_on_exit)
			co.input_event.connect(_on_input_event)


func _on_enter():
	if not _combat.active:
		_set_highlight(true)
		GameCursor.use_loot()


func _on_exit():
	_set_highlight(false)
	GameCursor.use_default()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action("highlight_interactives"):
		if event.is_pressed():
			if not event.is_echo():
				_set_highlight(true)
		else:
			_set_highlight(false)


func _set_highlight(state: bool) -> void:
	for mesh in _mask_meshes:
		mesh.visible = state


func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	# todo: maybe introduce global signal like "loot_requested", emit it with
	# the lootable reference? And the signal would be observed by the
	# ExplorationController. That would make scripting events easier, less
	# conditions... But then it should also handle the hover state, which is
	# uglyyyy
	if event is InputEventMouseButton:
		if not event.pressed and not _combat.active:
			var characters = _controlled_characters.get_selected()
			if characters.size() > 0 and characters[0].can_move_freely():
				# todo: will result in character standing on the object if it's
				# not navmesh-modifying static collider such as dead body...
				# calculate the object's interactable radius and find nearest
				# pont from the character?
				var movement = CharacterExplorationMovement.new(global_position)
				characters[0].action = movement
				await movement.goal_reached
				# todo: check whether actually close enough to the object?
				# Create some bounding box around all collision objects and
				# check its proximity? Or create area3d for each interactable?
				_level_gui.open_inventory()
				_level_gui.open_lootable(lootable)
