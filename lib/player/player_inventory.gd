class_name PlayerInventory
extends SlotContainer


## Get all equipment that can be assigned to given slot. If -1 is given, all
## equipment is returned.
func get_by_slot(slot: ItemEquipment.Slot) -> Array[Item]:
	var out: Array[Item] = []
	out.assign(_entities.values().filter(func (v: ItemEquipment) -> bool: return v is ItemEquipment && (slot == -1 || slot in v.slot)))
	return out


func get_entity(index: int) -> ItemRef:
	return super.get_entity(index)


func can_assign(entity: Slottable, _slot_i: int = -1) -> bool:
	return entity is ItemRef


func _to_string() -> String:
	return "<PlayerInventory#%s>" % get_instance_id()
