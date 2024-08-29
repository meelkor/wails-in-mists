## SlotContainer is used to represent character's equipment. Should be indexed
## by ItemEquipment.Slot enum
class_name CharacterEquipment
extends SlotContainer


## Get item (or null) currently equipped in given slot
func get_entity(slot: ItemEquipment.Slot) -> ItemEquipment:
	return super.get_entity(slot)


## Overriding to ensure only equipments are equippable
func can_assign(item: Slottable, slot_i: int = -1) -> bool:
	var equipment := item as ItemEquipment
	return equipment and slot_i in equipment.slot


func _to_string() -> String:
	return "<CharacterEquipment#%s>" % get_instance_id()
