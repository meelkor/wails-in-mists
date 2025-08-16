@tool
## Abstract item class which can be "used". Potions, talent books, some quest
## items...
@abstract
class_name ItemConsumable
extends Item


## Called when player uses the item in the inventory. Returns (possibly async)
## whether the item is "consumed" and should be removed (or stack size
## decremented)
@abstract
func on_use(_character: GameCharacter) -> bool
