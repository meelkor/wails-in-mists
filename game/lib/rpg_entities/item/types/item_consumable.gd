## Abstract item class which can be "used". Potions, talent books, some quest
## items...
class_name ItemConsumable
extends Item


## Called when player uses the item in the inventory. Returns (possibly async)
## whether the item is "consumed" and should be removed (or stack size
## decremented)
func on_use(_character: GameCharacter) -> bool:
	assert(false, "Needs to be implemented by subclass")
	await Signal() # just to make gdscript happy without ignoring warning
	return true
