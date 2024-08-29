## Container for representing character's available abilities or various
## ability bars in GUI.
class_name AbilityContainer
extends SlotContainer


func get_entity(index: int) -> Ability:
	return super.get_entity(index)


func _can_assign(entity: Slottable, _slot_i: int):
	return entity is Ability


func _to_string() -> String:
	return "<AbilityConainer#%s>" % get_instance_id()
