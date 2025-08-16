## Singleton service node available under as `global` used to access some
## well-known nodes such as player object, so we don't need to write the whole
## path everytime we need to access it from somewhere.
## todo: use DI instead of singleton? Where BaseLevel creates new injector, so
## level stuff can access this, but this cannot access level's stuff? But then
## LevelTester cannot work the way it does...

extends Node
class_name Global

var _message_log := MessageLog.new()

## Navigation mesh should be rebaked when emitted
signal rebake_navigation_mesh_request()


## Tree's create_timer wrapper which can be used from resources that do not
## have access to the tree.
func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


## Get level's controlled characters node if it exists
func message_log() -> MessageLog:
	return _message_log


## Function that should be called whenever contants of the
## navigation_mesh_source_group group changes.
func rebake_navigation_mesh() -> void:
	rebake_navigation_mesh_request.emit()
