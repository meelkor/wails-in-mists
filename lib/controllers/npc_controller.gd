# CharacterController specific for NPCs
class_name NpcController
extends CharacterController

@onready var _combat: Combat = di.inject(Combat)


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


## Start checks related to when player character enters NPC's sight: start
## combat
func _on_sight_entered(ctrl_or_cullable: Node3D) -> void:
	if character.alive:
		var ctrl := ctrl_or_cullable as PlayerController
		if ctrl and npc.is_enemy and not _combat.has_npc(npc):
			_combat.activate(npc)


## Add given NPC to the given participant list + add all its valid npc
## neighbours
func _add_npc_participants(participants: Array[NpcCharacter], ctrl: NpcController) -> void:
	participants.append(ctrl.npc)
	var neighbours := ctrl.get_neighbours()
	for neighbour in neighbours:
		if not participants.has(neighbour.npc) and (neighbour.npc.is_enemy or not npc.is_enemy):
			_add_npc_participants(participants, neighbour)
