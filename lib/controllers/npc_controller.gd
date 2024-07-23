# CharacterController specific for NPCs
class_name NpcController
extends CharacterController

@onready var _combat: Combat = di.inject(Combat)
@onready var _base_level: BaseLevel = di.inject(BaseLevel)

# Just a type helper since we cannot override the self.character type, but this
# controller should always have the NpcCharacter type.
var npc: NpcCharacter:
	get: return character

### Public ###

# Get list of NpcControllers which are in sight distance (excluding itself)
func get_neighbours() -> Array[NpcController]:
	var out: Array[NpcController] = [];
	var bodies = $SightArea.get_overlapping_bodies()
	out.assign(bodies.filter(func (body): return body is NpcController and body != self))
	return out

### Lifecycle ###

func _init() -> void:
	# all fow cullables need to be invisible by deafult
	visible = false

func _ready() -> void:
	super._ready()
	$SightArea.body_entered.connect(_on_sight_entered)
	character.died_in_combat.connect(_handle_death)

func _process(delta) -> void:
	super._process(delta)
	_run_selection_circle_logic()

### Private ###

# Start checks related to when player character enters NPC's sight: start
# combat
func _on_sight_entered(ctrl_or_cullable) -> void:
	if ctrl_or_cullable is PlayerController and npc.is_enemy and not _combat.has_npc(npc):
		_combat.activate(character)

# Add given NPC to the given participant list + add all its valid npc
# neighbours
func _add_npc_participants(participants: Array[NpcCharacter], ctrl: NpcController) -> void:
	participants.append(ctrl.npc)
	var neighbours = ctrl.get_neighbours()
	for neighbour in neighbours:
		if not participants.has(neighbour.npc) and neighbour.npc.is_enemy:
			_add_npc_participants(participants, neighbour)

# Update selection circle visibility/color based on controller's state
func _run_selection_circle_logic() -> void:
	if circle_needs_update:
		if hovered:
			if character.is_enemy:
				update_selection_circle(true, Vector3(0.612, 0.098, 0.098), 0.45)
			else:
				update_selection_circle(true, Vector3(0.369, 0.592, 0.263), 0.45)
		else:
			update_selection_circle(false)
		circle_needs_update = false

func _handle_death() -> void:
	var lootable_mesh = LootableMesh.new()
	lootable_mesh.lootable = Lootable.new()
	# todo: fill lootable according to npc's loot_table / gear
	var skeleton: Skeleton3D = find_child("Skeleton3D")
	var orig_transform = global_transform
	skeleton.reparent(lootable_mesh)
	skeleton.global_transform = orig_transform
	get_parent().remove_child(self)
	self.queue_free()
	skeleton.physical_bones_start_simulation()
	# Normalize physical bones for ragdolls
	skeleton.owner = lootable_mesh
	for child in skeleton.get_children():
		# fixme: shouldn't be needed after 4.3 release
		# https://github.com/godotengine/godot/issues/81480
		child.owner = lootable_mesh
	var bones = skeleton.find_children("", "PhysicalBone3D")
	_base_level.add_child(lootable_mesh)
	lootable_mesh.owner = _base_level
	for bone in bones:
		# todo: create some one or two static colliders based on the bone
		# location after second or so
		if bone is PhysicalBone3D:
			bone.input_ray_pickable = true
