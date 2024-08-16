## Resource representing any kind of lootable object in the level. Should be
## displayed using the LootableSlot node.
class_name Lootable
extends ItemContainer

@export var name: String = "Container"

## Number of available slots in this lootable, so we can limit storage in case
## of player-managed cotainers. When 0, the number of slots coresponds to number
## of items
@export var slots: int = 0

## todo: we need a way to match lootable resource instance in save to object on
## map. We could have some resources like: { static_container: container_id }
## for static containers on the map. { dead_body: character_resource } for dead
## bodies etc.
## @export var ref: LootableRef

### Lifecycle ###

func _init() -> void:
	if slots == 0:
		slots = items.size()
