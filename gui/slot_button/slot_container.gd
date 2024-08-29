## Structure for use with slot buttons that allows dragging entities (items,
## abilities) between other containers. May serve as a base class for any kind
## of inventory, ability bar, lootable etc.
class_name SlotContainer
extends Resource

## int => Slottable, changes from outside should not be made directly, but via
## some of the SlotContainer methods
@export var _entities: Dictionary


## If true, dragging the entity from this slot doesn't actually remove its
## entity. Use in container nodes.
func is_static() -> bool:
	return false


## If returns true, player can drag from this container.  Use in container
## nodes.
func is_giver() -> bool:
	return true


## If returns true, player can drag into this container.  Use in container
## nodes.
func is_taker() -> bool:
	return true


## If returns true, when entity is dragged into nothingness, the dragged entity
## should be removed from the entity.
func can_remove() -> bool:
	return false


## Can be overriden by subclasses to create picky containers such as character
## equipment container. The UI node that represents slot in this container
## should call this method to ensure it is accepted.
func can_assign(_entity: Slottable, _slot_i: int = -1) -> bool:
	return true


## Add given entity on given index, or on the first empty slot in the map if no
## slot given. Returns entity if the action replaced entity. Otherwise null. If
## null given instead of entity, the slot is removed.
##
## Should be used for player-initiated adding. For programatical that bypasses
## conditions such is is_taker, use set_entities.
##
## Override in type-specific containers to set expected arg type
func add_entity(entity: Slottable, slot_i: int = -1) -> AssignResult:
	var result := AssignResult.new()
	if entity:
		if slot_i == -1:
			slot_i = 0
			while true:
				if not slot_i in _entities:
					break
				slot_i += 1

		if can_assign(entity, slot_i):
			var old_entity: Slottable = _entities.get(slot_i, null)
			_entities[slot_i] = entity
			result.entity = old_entity
			result.ok = true
	else:
		result.entity = _entities.get(slot_i, null)
		_entities.erase(slot_i)
		result.ok = true

	emit_changed()
	return result


## Set given entities replacing all existing ones and bypasing any filters,
## emitting single changed signal.
func set_entities(entities: Array[Slottable]) -> void:
	_entities.clear()
	for i in range(entities.size()):
		_entities[i] = entities[i]
	emit_changed()


## Return number of entities in the container
func size() -> int:
	return _entities.size()


## Wrapper around _entities.get which can be overriden by subclasses to make
## type-safe
func get_entity(index: int) -> Slottable:
	return _entities.get(index, null)


## Can be overriden by subclasses to make type-safe
func get_all() -> Array[Slottable]:
	var all: Array[Slottable]
	all.assign(_entities.values())
	return all


func clear() -> void:
	_entities.clear()
	emit_changed()


func erase(slot_i: int) -> void:
	_entities.erase(slot_i)


class AssignResult:
	extends RefCounted

	var entity: Slottable

	var ok: bool = false


func _to_string() -> String:
	return "<SlotContainer#%s>" % get_instance_id()
