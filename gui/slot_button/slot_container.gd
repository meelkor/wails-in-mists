## Structure for use with slot buttons that allows dragging entities (items,
## abilities) between other containers. May serve as a base class for any kind
## of inventory, ability bar, lootable etc.
class_name SlotContainer
extends Resource

## int => Slottable, changes from outside should not be made directly, but via
## some of the SlotContainer methods
@export var _entities: Dictionary

## If true, _can_assign is ignored and nothing can be dropped into the slot
@export var read_only: bool = false

## If true, dragging the entity from this slot doesn't actually remove its
## entity
@export var copy_dragged: bool = false


## Add given entity on given index, or on the first empty slot in the map if no
## slot given. Returns entity if the action replaced entity. Otherwise null. If
## null given instead of entity, the slot is removed.
##
## Override in type-specific containers to set expected arg type
func add_entity(entity: Slottable, slot_i: int = -1) -> AssignResult:
	var result = AssignResult.new()
	if entity:
		if slot_i == -1:
			slot_i = 0
			while true:
				if not slot_i in _entities:
					break
				slot_i += 1

		if not read_only and _can_assign(entity, slot_i):
			var old_entity = _entities.get(slot_i, null)
			_entities[slot_i] = entity
			result.entity = old_entity
			result.ok = true
	else:
		result.entity = _entities.get(slot_i, null)
		_entities.erase(slot_i)
		result.ok = true

	emit_changed()
	return result


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


## Can be overriden by subclasses to create picky containers such as character
## equipment container.
func _can_assign(_entity: Slottable, _slot_i: int):
	return true


class AssignResult:
	extends RefCounted

	var entity: Slottable

	var ok: bool = false


func _to_string() -> String:
	return "<SlotContainer#%s>" % get_instance_id()
