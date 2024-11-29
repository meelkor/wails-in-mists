# CharacterController specific for NPCs
class_name NpcController
extends CharacterController

@onready var _combat: Combat = di.inject(Combat)
@onready var _base_level: BaseLevel = di.inject(BaseLevel)

## Just a type helper since we cannot override the self.character type, but
## this controller should always have the NpcCharacter type.
var npc: NpcCharacter:
	get: return character

### Public ###


# Get list of NpcControllers which are in sight distance (excluding itself)
func get_neighbours() -> Array[NpcController]:
	var out: Array[NpcController] = [];
	var bodies := sight_area.get_overlapping_bodies()
	out.assign(bodies.filter(func (body: Node3D) -> bool: return body is NpcController and body != self))
	return out

### Lifecycle ###


func _init() -> void:
	# all fow cullables need to be invisible by deafult
	visible = false


func _ready() -> void:
	super._ready()
	sight_area.body_entered.connect(_on_sight_entered)
	character.died_in_combat.connect(_handle_death)


## Start checks related to when player character enters NPC's sight: start
## combat
func _on_sight_entered(ctrl_or_cullable: Node3D) -> void:
	var ctrl := ctrl_or_cullable as PlayerController
	if ctrl and npc.is_enemy and not _combat.has_npc(npc):
		_combat.activate(npc)


## Add given NPC to the given participant list + add all its valid npc
## neighbours
func _add_npc_participants(participants: Array[NpcCharacter], ctrl: NpcController) -> void:
	participants.append(ctrl.npc)
	var neighbours := ctrl.get_neighbours()
	for neighbour in neighbours:
		if not participants.has(neighbour.npc) and neighbour.npc.is_enemy:
			_add_npc_participants(participants, neighbour)


func _handle_death(src: Vector3) -> void:
	_activate_ragdoll((global_position - src).normalized() * 2.)
	var lootable_mesh := preload("res://lib/level/lootable_mesh.tscn").instantiate() as LootableMesh
	lootable_mesh.lootable = Lootable.new()
	# todo: fill lootable according to npc's loot_table / gear
	var skeleton: Skeleton3D = find_child("Skeleton3D")
	var orig_transform := global_transform
	lootable_mesh.global_transform = orig_transform
	skeleton.transform = Transform3D.IDENTITY
	get_parent().remove_child(self)
	skeleton.reparent(lootable_mesh)
	# Normalize physical bones for ragdolls
	skeleton.owner = lootable_mesh
	for child in skeleton.get_children():
		child.owner = lootable_mesh
	var bones := skeleton.find_children("", "PhysicalBone3D")
	_base_level.add_child(lootable_mesh)
	lootable_mesh.owner = _base_level
	for bone: PhysicalBone3D in bones:
		if not bone.is_in_group("leg_bone"):
			# todo: create some one or two static colliders based on the bone
			# location after second or so
			bone.input_ray_pickable = true

	self.queue_free()
