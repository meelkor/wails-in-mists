## Contains all information about player's progress, characters etc. Represents
## main content of saved game.
class_name PlayerState
extends Resource

@export var inventory: PlayerInventory = PlayerInventory.new()

@export var characters: Array[PlayableCharacter] = []
