## SlotContainer is used to represent character's equipment. Should be indexed
## by ItemEquipment.Slot enum
@tool
class_name CharacterEquipment
extends SlotContainer

@warning_ignore_start("unused_private_class_variable")
@export_tool_button("Armor", "ToolAddNode") var _add_armor: Callable = func () -> void:
	EditorInterface.popup_quick_open(_tool_on_add_slottable_selected.bind(ItemEquipment.Slot.ARMOR, ItemRef), ["ItemArmor"])

@export_tool_button("Main", "ToolAddNode") var _add_main: Callable = func () -> void:
	EditorInterface.popup_quick_open(_tool_on_add_slottable_selected.bind(ItemEquipment.Slot.MAIN, WeaponRef), ["ItemWeapon"])

@export_tool_button("Off", "ToolAddNode") var _add_off: Callable = func () -> void:
	EditorInterface.popup_quick_open(_tool_on_add_slottable_selected.bind(ItemEquipment.Slot.OFF, WeaponRef), ["ItemEquipment"])

@export_tool_button("Accessory", "ToolAddNode") var _add_accessory: Callable = func () -> void:
	EditorInterface.popup_quick_open(_tool_on_add_slottable_selected.bind(ItemEquipment.Slot.ACCESSORY, ItemRef), ["ItemEquipment"])
@warning_ignore_restore("unused_private_class_variable")


## Get item (or null) currently equipped in given slot
func get_entity(slot: ItemEquipment.Slot) -> ItemRef:
	return super.get_entity(slot)


## Overriding to ensure only equipments are equippable
##
## todo: come up can equip (stats etc.) validation... is it even needed tho?
func can_assign(item: Slottable, slot_i: int = -1) -> bool:
	var ref := item as ItemRef
	if ref:
		var equipment := ref.item as ItemEquipment
		return equipment and slot_i in equipment.slot
	return false


func get_weapon() -> WeaponRef:
	return get_entity(ItemEquipment.Slot.MAIN)


## Find a slot for given item. Prefer empty slots.
func get_available_slot(item: ItemRef) -> int:
	var last_valid: int = -1
	for slot_i: int in ItemEquipment.Slot.values():
		if can_assign(item, slot_i):
			last_valid = slot_i
			if not get_entity(slot_i):
				break
	return last_valid


## Wrapper which picks the item equipment instances from item references for
## easier access when we do not need instance specific details such as weapon
## quality.
func get_all_equipment() -> Array[ItemEquipment]:
	var out: Array[ItemEquipment] = []
	for item_ref: ItemRef in get_all():
		out.append(item_ref.item)
	return out


func _to_string() -> String:
	return "<CharacterEquipment#%s>" % get_instance_id()


func _get_slottable_type() -> StringName:
	return "ItemRef"


func _tool_on_add_slottable_selected(res_path: StringName, slot: int, Wrapper: GDScript) -> void:
	if res_path == "":
		return
	var item := load(res_path)
	var ref := Wrapper.new() as ItemRef
	ref.item = item
	_entities.set(slot, ref)
	emit_changed()
	notify_property_list_changed()
	EditorInterface.mark_scene_as_unsaved()
