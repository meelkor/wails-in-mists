extends Node
class_name PlayerState

## Following stored inventory resource instance should be always used for
## inventory, even when its content is then changed, so we can easily reference
## it in various nodes in the editor

# piiiiiiiiiiiiiiiiicovina, to musi by dynamicke, bo to neni inventory ale charater eqiup omg
var inventory: PlayerInventory = PlayerInventory.new()

var characters: Array[PlayableCharacter] = []
