## TODO: maybe merge SpawnedNpcs and ControlledCharacers nodes into one since
## they share logic quite a bit
class_name SpawnedNpcs
extends Node

signal character_clicked(npc: GameCharacter, type: GameCharacter.InteractionType)

var changed_observer := ResourceObserver.new()

### Public ###

## Get character resource for every spawned NPC
func get_characters() -> Array[NpcCharacter]:
	var npc_children := get_children()
	var npc_chars := npc_children.map(func (ctrl: NpcController) -> NpcCharacter: return ctrl.character)
	var out: Array[NpcCharacter] = []
	out.assign(npc_chars)
	return out


## "Spawn" the character, adding its controller into the world
func spawn(ctrl: NpcController) -> void:
	ctrl.character.clicked.connect(func (type: GameCharacter.InteractionType) -> void: character_clicked.emit(ctrl.character, type))
	add_child(ctrl)
	changed_observer.update(get_characters())
