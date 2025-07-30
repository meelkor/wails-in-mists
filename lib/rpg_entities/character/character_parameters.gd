## Contains RPG info about the character. Those shouldn't change for NPCs so we
## do not want to store them in gamesave and thus need to be always stored in
## saved resource.
class_name CharacterParameters
extends Resource

## CharacterAttribute resources mapped to the attribute values
@export var attributes: Dictionary[CharacterAttribute, int] = {}

## Note: if we ever need modify NPC's equipment during the game, is should be
## done via some GameModification or flag that will be stored in gamesave, but
## the parameters should stay the same.
@export var equipment := CharacterEquipment.new()

## Character's level. Available talent slot count and attribute points are
## based of this value.
@export var level: int = 1:
	set(v):
		if level != v:
			level = v
			emit_changed()

## Currently active buffs. Called static because I expect to have buffs
## provided by talents/equipment in the future via modifiers. (buffs will be
## able to provide buffs lmao)
@export var static_buffs: Dictionary[BuffOnset, Buff] = {}

## Currently "active" talent packs.
@export var talents := TalentList.new()
