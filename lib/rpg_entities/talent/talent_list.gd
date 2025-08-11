## Slot container used for talent packs so the packs can be dragged around
## primarily in character dialog
@tool
class_name TalentList
extends SlotContainer

var _active_talents: TalentList


## Provided list should be the list containing currently equipped talents. When
## provided the list is behaving as "available talent giver".
func connect_active_talents(active_talents: TalentList) -> void:
	_active_talents = active_talents
	# is_disabled is dependant on active talents state
	_active_talents.changed.connect(func () -> void: changed.emit())


func is_taker() -> bool:
	return !_active_talents


func is_giver() -> bool:
	return !!_active_talents


func is_static() -> bool:
	return !!_active_talents


func can_remove() -> bool:
	return !_active_talents


func is_disabled(entity: Slottable) -> bool:
	return _active_talents and _active_talents.includes(entity)


func can_assign(entity: Slottable, _slot_i: int = -1) -> bool:
	return entity is TalentPack


## Get talents from all talent packs
func get_all_talents() -> Array[Talent]:
	var out: Array[Talent] = []
	for pack: TalentPack in _entities.values():
		out.append_array(pack.talents)
	return out


func _to_string() -> String:
	return "<TalentList#%s>" % get_instance_id()


func _get_slottable_type() -> StringName:
	return "TalentPack"
