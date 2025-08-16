## Contains all information about player's progress, characters etc. Represents
## main content of saved game.
class_name PlayerState
extends Resource

@export var inventory: PlayerInventory = PlayerInventory.new()

@export var characters: Array[PlayableCharacter] = []


## Get main character resource
func get_mc() -> MainCharacter:
	var index := characters.find_custom(func (c: PlayableCharacter) -> bool: return c is MainCharacter)
	if index == -1:
		assert(false, "Player has no main character")
	return characters[index]
