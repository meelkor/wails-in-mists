## Node that makes child mesh interactable, opening looting interface with
## content based on the given lootable resource
class_name LootableMesh
extends Node3D

var di = DI.new(self)

@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)
@onready var _combat: Combat = di.inject(Combat)
@onready var _level_gui: LevelGui = di.inject(LevelGui)

@export var lootable: Lootable

## Area a character needs to be in to be able to
@onready var _lootable_area: Area3D = %LootableArea

@onready var _click_observer = ClickObserver.new()

## Reference to the currently open dialog so we can easily close it
var _current_dialog: Node

## Character which opened the currently open dialog
var _current_opener: GameCharacter

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

	# TODO: change the collision sphere based on the mesh's size
	var collision_objects = find_children("", "CollisionObject3D")
	for co in collision_objects:
		if co is CollisionObject3D:
			co.mouse_entered.connect(_on_enter)
			co.mouse_exited.connect(_on_exit)
			# Currently when cursor moves from CollisionObject3D onto mouse
			# blocking control, it doesn't fire the exit event. We detect that
			# exit by observing LevelGui events
			_level_gui.mouse_exited.connect(_on_exit)
			_click_observer.add(co)

	_click_observer.clicked.connect(_on_click)
	_lootable_area.body_exited.connect(_body_exited)


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
	elif event.is_action("abort"):
		if not event.is_pressed() and _current_dialog:
			_close_dialog()


func _set_highlight(state: bool) -> void:
	for mesh in _mask_meshes:
		mesh.visible = state


func _on_click() -> void:
	# todo: maybe introduce global signal like "loot_requested", emit it with
	# the lootable reference? And the signal would be observed by the
	# ExplorationController. That would make scripting events easier, less
	# conditions... But then it should also handle the hover state, which is
	# uglyyyy
	if not _combat.active:
		var closest = _get_closest_character()
		if closest["character"] and closest["character"].can_move_freely():
			if closest["position"] != null:
				var target_pos: Vector3 = closest["position"]
				# Move just slightly further that the exect intersection point
				# to ensure the character's collider collides with the area
				var move_to = target_pos - (target_pos - global_position).normalized() * 0.5
				var movement = CharacterExplorationMovement.new(move_to)
				closest["character"].action = movement
				await movement.goal_reached
			_level_gui.open_inventory()
			_open_dialog(closest["character"])


## Open loot dialog for this lootable mesh. Validates that given character's
## distance to the object isn't too far and closes when it happens.
func _open_dialog(character: GameCharacter):
	if _character_close_enough(character) and not _current_dialog:
		var dialog = preload("res://gui/loot_dialog/loot_dialog.tscn").instantiate()
		dialog.lootable = lootable
		add_child(dialog)
		_current_dialog = dialog
		_current_opener = character
		dialog.tree_exited.connect(_clear_state, CONNECT_ONE_SHOT)


## Remove the dialog from tree (previously connected signal clears the
## _current_dialog ref)
func _close_dialog():
	if _current_dialog:
		remove_child(_current_dialog)
		_level_gui.close_inventory()


## Get currently selected character which is closest to this lootable mesh,
## returning the character and a position bordering with the lootable area
## that's closest to that character. Returned position may be null if there
## is not need to move
func _get_closest_character() -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var best_disance = INF
	var best_character: GameCharacter
	var best_position: Vector3
	var characters = _controlled_characters.get_selected()

	for chara in characters:
		if _character_close_enough(chara):
			# Nothing to do really
			return { "character": chara, "position": null }

		var query = PhysicsRayQueryParameters3D.create(chara.position, global_position)
		query.collide_with_bodies = false
		query.collide_with_areas = true
		var imm_mask = Utils.get_collision_layer("immediate")
		query.collision_mask = imm_mask
		_lootable_area.collision_layer = _lootable_area.collision_mask | imm_mask
		var result = space_state.intersect_ray(query)
		_lootable_area.collision_layer = _lootable_area.collision_mask & ~imm_mask
		var distance_to_area = chara.position.distance_squared_to(result["position"])
		if distance_to_area < best_disance:
			best_position = result["position"]
			best_disance = distance_to_area
			best_character = chara

	return { "character": best_character, "position": best_position }


## Check whether given character is close enough to the objec to open in right
## now
func _character_close_enough(character: PlayableCharacter) -> bool:
	var ctrl = _controlled_characters.get_controller(character)
	return ctrl and _lootable_area.overlaps_body(ctrl)


## Whenever body exits the loot area, check whether it wasn't character who is
## currently "looking into" this lootable
func _body_exited(body: CollisionObject3D) -> void:
	if body is CharacterController:
		if body.character == _current_opener:
			_close_dialog()


## Remove local references to objects related to last lootable opening
func _clear_state() -> void:
	_current_opener = null
	_current_dialog = null
