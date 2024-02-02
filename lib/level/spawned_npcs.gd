class_name SpawnedNpcs
extends Node

### Public ###

# Get character resource for every spawned NPC
func get_characters() -> Array[NpcCharacter]:
	var npc_children = get_children()
	var npc_chars = npc_children.map(func (ctrl): return ctrl.character)
	var out: Array[NpcCharacter] = []
	out.assign(npc_chars)
	return out
