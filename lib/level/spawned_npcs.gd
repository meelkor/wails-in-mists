class_name SpawnedNpcs
extends Node

### Public ###

## Get character resource for every spawned NPC
func get_characters() -> Array[NpcCharacter]:
	var npc_children = get_children()
	var npc_chars = npc_children.map(func (ctrl): return ctrl.character)
	var out: Array[NpcCharacter] = []
	out.assign(npc_chars)
	return out

## Get controller for given NPC which is expected to be spawned by now.
func get_controller(character: NpcCharacter) -> NpcController:
	var c = get_children().filter(func (ctrl): return ctrl.character == character)
	assert(c.size() == 1, "Trying to get controlelr for non-spawned character")
	return c[0]
