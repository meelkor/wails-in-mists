extends Object
class_name PlayerInventory

var items: Array[GeneralItem] = []

signal changed()

func get_weapons() -> Array[WeaponItem]:
	return items.filter(func (v): v is WeaponItem)
