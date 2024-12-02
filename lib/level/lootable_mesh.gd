## Node that makes child mesh interactable, with methods to open looting
## interface with content based on the given lootable resource. This node is
## mostly passive only emitting related singals on BaseLevel. The opening /
## highlighting should be done by currently active controls node.
class_name LootableMesh
extends Node3D

const LootDialog := preload("res://gui/loot_dialog/loot_dialog.gd")

var di := DI.new(self)

@onready var _controlled_characters := di.inject(ControlledCharacters) as ControlledCharacters
@onready var _level_gui := di.inject(LevelGui) as LevelGui
@onready var _base_level := di.inject(BaseLevel) as BaseLevel

@export var lootable: Lootable

## When true, outline around the object is displayed. Usually used on hover.
var highlighted: bool = false:
	set(state):
		for mesh in _mask_meshes:
			mesh.visible = state
		highlighted = state


## Area a character needs to be in to be able to
@onready var _lootable_area: Area3D = %LootableArea

@onready var _click_observer := ClickObserver.new()

## Character which opened the currently open dialog
var _current_opener: GameCharacter

var _mask_meshes: Array[MeshInstance3D]


func _ready() -> void:
	var meshes := find_children("", "MeshInstance3D")
	for mesh in meshes:
		var mask := mesh.duplicate() as MeshInstance3D
		mask.material_override = preload("res://materials/outline/outline.tres")
		mask.layers = 0b1000;
		mesh.get_parent().add_child(mask)
		mask.visible = false
		_mask_meshes.append(mask)

	# TODO: change the collision sphere based on the mesh's size
	var collision_objects := find_children("", "CollisionObject3D")
	for co: CollisionObject3D in collision_objects:
		co.mouse_entered.connect(_on_enter)
		co.mouse_exited.connect(_on_exit)
		# Currently when cursor moves from CollisionObject3D onto mouse
		# blocking control, it doesn't fire the exit event. We detect that
		# exit by observing LevelGui events
		_level_gui.mouse_exited.connect(func () -> void: _on_exit()) # w/o lambda engine cries that the fn is already connected to singal
		_click_observer.add(co)

	_click_observer.clicked.connect(_on_click)
	_lootable_area.body_exited.connect(_body_exited)


## Try to open with currently selected character. Should be always used for
## lootable meshes instead of directly calling LevelGui.open_lootable, to make
## sure the character moves to the lootable's position.
func open() -> void:
	var closest := _get_closest_character()
	if closest.character and closest.character.is_free():
		if closest.position != closest.character.position:
			var target_pos: Vector3 = closest.position
			# Move just slightly further that the exect intersection point
			# to ensure the character's collider collides with the area
			var move_to := target_pos - (target_pos - global_position).normalized() * 0.5
			var movement := CharacterExplorationMovement.new(move_to)
			closest.character.action = movement
			await movement.goal_reached
		_level_gui.open_inventory()
		_open_dialog(closest.character)


func _on_enter() -> void:
	_base_level.lootable_hovered.emit(self, true)


func _on_exit() -> void:
	_base_level.lootable_hovered.emit(self, false)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action("highlight_interactives"):
		if event.is_pressed():
			if not event.is_echo():
				highlighted = true
		else:
			highlighted = false


## Propagate the event to the base level, so the current controls node can
## decide, whether we should loot it.
func _on_click() -> void:
	_base_level.loot_requested.emit(self)


## Open loot dialog for this lootable mesh. Validates that given character's
## distance to the object isn't too far and closes when it happens.
func _open_dialog(character: PlayableCharacter) -> void:
	if _character_close_enough(character):
		_level_gui.open_lootable(lootable)


## Get currently selected character which is closest to this lootable mesh,
## returning the character and a position bordering with the lootable area
## that's closest to that character. Returned position may be null if there
## is not need to move
func _get_closest_character() -> ClosestLooterCharacter:
	var out := ClosestLooterCharacter.new()
	var space_state := get_world_3d().direct_space_state
	var best_disance := INF
	var characters := _controlled_characters.get_selected()

	for chara in characters:
		if _character_close_enough(chara):
			# Nothing to do really
			out.position = chara.position
			out.character = chara
			break

		var query := PhysicsRayQueryParameters3D.create(chara.position, global_position)
		query.collide_with_bodies = false
		query.collide_with_areas = true
		var imm_mask := Utils.get_collision_layer("immediate")
		query.collision_mask = imm_mask
		_lootable_area.collision_layer = _lootable_area.collision_mask | imm_mask
		var result := space_state.intersect_ray(query)
		_lootable_area.collision_layer = _lootable_area.collision_mask & ~imm_mask
		var distance_to_area := chara.position.distance_squared_to(result["position"] as Vector3)
		if distance_to_area < best_disance:
			out.position = result["position"]
			best_disance = distance_to_area
			out.character = chara
	return out


## Check whether given character is close enough to the objec to open in right
## now
func _character_close_enough(character: PlayableCharacter) -> bool:
	var ctrl := _controlled_characters.get_controller(character)
	return ctrl and _lootable_area.overlaps_body(ctrl)


## Whenever body exits the loot area, check whether there is any character
## close enough to be currently "looking into" this lootable
func _body_exited(_body: Node3D) -> void:
	var bodies := _lootable_area.get_overlapping_bodies()
	var keep_open := false
	for body in bodies:
		keep_open = keep_open or body is PlayerController
	if not keep_open:
		_level_gui.close_lootable(lootable)


## Remove local references to objects related to last lootable opening
func _clear_state() -> void:
	_current_opener = null


class ClosestLooterCharacter:
	extends RefCounted

	var character: PlayableCharacter
	var position: Vector3
