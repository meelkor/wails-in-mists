## TODO: maybe merge SpawnedNpcs and ControlledCharacers nodes into one since
## they share logic quite a bit
class_name SpawnedNpcs
extends Node

signal character_clicked(npc: NpcCharacter)

var changed_observer := ResourceObserver.new()

### Public ###

## Get character resource for every spawned NPC
func get_characters() -> Array[NpcCharacter]:
	var npc_children := get_children()
	var npc_chars := npc_children.map(func (ctrl: NpcController) -> NpcCharacter: return ctrl.character)
	var out: Array[NpcCharacter] = []
	out.assign(npc_chars)
	return out

## Get controller for given NPC which is expected to be spawned by now.
func get_controller(character: NpcCharacter) -> NpcController:
	var c := get_children().filter(func (ctrl: NpcController) -> bool: return ctrl.character == character)
	assert(c.size() == 1, "Trying to get controlelr for non-spawned character")
	return c[0]


## "Spawn" the character, adding its controller into the world
func spawn(ctrl: NpcController) -> void:
	ctrl.clicked.connect(func (character: GameCharacter) -> void: character_clicked.emit(character))
	add_child(ctrl)
	changed_observer.update(get_characters())
