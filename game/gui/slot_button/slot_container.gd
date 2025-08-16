## Structure for use with slot buttons that allows dragging entities (items,
## abilities) between other containers. May serve as a base class for any kind
## of inventory, ability bar, lootable etc.
@tool
@abstract
class_name SlotContainer
extends Resource

## int => Slottable, changes from outside should not be made directly, but via
## some of the SlotContainer methods
@export var _entities: Dictionary[int, Slottable] = {}


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


## Can be overriden to provide per-entity disabled state. Entity may be null.
func is_disabled(_entity: Slottable) -> bool:
	return false


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


## Wrapper around add_entity method, which tries to move entity from one
## container to another, switching the items if necessary. If switching cannot
## be done (= imcompatible slottable types), nothing happens
##
## todo: make sure the logic here isn't duplicate with add_entity... it prolly
## is
func move_entity(dst_container: SlotContainer, src_idx: int, dst_idx: int = -1) -> void:
	var orig_state := _entities.duplicate()
	var orig_dst_state := dst_container._entities.duplicate()
	var entity := get_entity(src_idx)
	if entity:
		var result := dst_container.add_entity(entity, dst_idx)
		if result.ok:
			if result.entity:
				var switch_result := add_entity(result.entity, src_idx)
				if not switch_result.ok:
					# the assignment result in entity switch but the switched
					# entity cannot be assigned back to this container -> abort
					# opration, undo!
					_entities.assign(orig_state)
					dst_container._entities.assign(orig_dst_state)
					# todo: probably not the best way to do this, but it's
					# safe... rethink this a little
			else:
				erase(src_idx)


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
	return _entities.values()


func clear() -> void:
	_entities.clear()
	emit_changed()


func erase(slot_i: int) -> void:
	_entities.erase(slot_i)
	emit_changed()


func includes(entity: Slottable) -> bool:
	return _entities.values().has(entity)


func _to_string() -> String:
	return "<SlotContainer#%s>" % get_instance_id()


@abstract func _get_slottable_type() -> StringName


## Class describing result of the entity assignment into container since it may
## result in a orphaned entity, which needs to taken care of.
class AssignResult:
	extends RefCounted

	## Entity which the operation replaced and thus is now ophaned
	var entity: Slottable

	## Whether the entity was assigned to the container
	var ok: bool = false
