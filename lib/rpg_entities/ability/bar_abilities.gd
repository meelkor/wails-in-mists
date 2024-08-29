## Represents content of an ability bar
class_name BarAbilities
extends SlotContainer


func get_entity(index: int) -> Ability:
	return super.get_entity(index)


func can_remove() -> bool:
	return true


# func can_assign(_entity: Slottable, _slot_i: int = -1) -> bool:
