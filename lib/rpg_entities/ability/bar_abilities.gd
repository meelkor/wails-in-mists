## Represents content of an ability bar
@tool
class_name BarAbilities
extends SlotContainer


var _available_abilities: SlotContainer


func _init(available_abilities: SlotContainer) -> void:
	_available_abilities = available_abilities
	available_abilities.changed.connect(_validate_available_abilities)


func get_entity(index: int) -> Ability:
	return super.get_entity(index)


func can_remove() -> bool:
	return true


func can_assign(entity: Slottable, _slot_i: int = -1) -> bool:
	var ability := entity as Ability
	return ability != null and _available_abilities.includes(entity)


## Ensure that all assigned abilities are still also included in the related
## (character's) available abilities container.
func _validate_available_abilities() -> void:
	var need_update := false
	for index in _entities:
		var ability := _entities[index]
		if not _available_abilities.includes(ability):
			need_update = true
			_entities.erase(index)
	if need_update:
		emit_changed()


func _to_string() -> String:
	return "<BarAbilities#%s>" % get_instance_id()


func _get_slottable_type() -> StringName:
	return "Ability"
