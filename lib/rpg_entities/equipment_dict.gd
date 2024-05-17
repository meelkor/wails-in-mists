# Type-safe alternative to storing equipment in dict. Allow changing equipped
# items and offers helpers for reading equipment's modifiers and parameters.
class_name EquipmentDict
extends RefCounted

# Signal emitted whenever equipment change
signal changed()

var main: ItemEquipment
var off: ItemEquipment
var armor: ItemArmor
var accessory: ItemEquipment

# Get item (or null) currently equipped in given slot
func from_slot(slot: ItemEquipment.Slot) -> ItemEquipment:
	if slot == ItemEquipment.Slot.ACCESSORY:
		return accessory
	elif slot == ItemEquipment.Slot.MAIN:
		return main
	elif slot == ItemEquipment.Slot.ARMOR:
		return armor
	elif slot == ItemEquipment.Slot.OFF:
		return off
	return null

# Returns previously equipped item. Needs to be put into inventory or
# something, otherwise it will be lost!
func equip(slot: ItemEquipment.Slot, item: ItemEquipment) -> ItemEquipment:
	var prev = from_slot(slot)
	if slot == ItemEquipment.Slot.ACCESSORY:
		accessory = item
	elif slot == ItemEquipment.Slot.MAIN:
		main = item
	elif slot == ItemEquipment.Slot.ARMOR:
		armor = item
	elif slot == ItemEquipment.Slot.OFF:
		off = item
	changed.emit()
	return prev

# Returns previously equipped item. Needs to be put into inventory or
# something, otherwise it will be lost!
func unequip(slot: ItemEquipment.Slot) -> ItemEquipment:
	var prev = from_slot(slot)
	equip(slot, null)
	changed.emit()
	return prev

func values() -> Array[ItemEquipment]:
	var out: Array[ItemEquipment] = []
	out.assign([main, off, armor, accessory].filter(func(v): return v != null))
	return out
