## Container for representing character's available abilities or various
## ability bars in GUI.
class_name AvailableAbilities
extends SlotContainer


func is_taker() -> bool:
	return false


func is_static() -> bool:
	return true


func get_entity(index: int) -> Ability:
	return super.get_entity(index)


func _to_string() -> String:
	return "<AvailableAbilities#%s>" % get_instance_id()
