# CharacterController specific for NPCs
class_name NpcController
extends CharacterController

# Emits when this NPC wants to start combat. Emitted array contains all NPC
# participants, that should be included in this combat.
signal initiated_combat(npcs: Array[NpcCharacter])

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

func _ready() -> void:
	super._ready()
	$SightArea.body_entered.connect(_on_sight_entered)

func _process(delta) -> void:
	super._process(delta)
	_run_selection_circle_logic()

### Private ###

# Start checks related to when player character enters NPC's sight: start
# combat, event etc.
func _on_sight_entered(ctrl_or_cullable) -> void:
	if ctrl_or_cullable is PlayerController and npc.is_enemy and not npc.active_combat:
		var npcs: Array[NpcCharacter] = []
		_add_npc_participants(npcs, self)
		initiated_combat.emit(npcs)

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
