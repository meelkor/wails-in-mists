## Singleton service node available under as `global` used to access some
## well-known nodes such as player object, so we don't need to write the whole
## path everytime we need to access it from somewhere.
## todo: use DI instead of singleton? Where BaseLevel creates new injector, so
## level stuff can access this, but this cannot access level's stuff? But then
## LevelTester cannot work the way it does...

extends Node
class_name Global

# Player state if exists should always be found under this path. Player state
# is expected to exist only after new game is created or existing loaded.
#
# todo: remake into resource
var PLAYER_STATE_PATH = ^"/root/GameRoot/PlayerState"

# If level is loaded, it should always have the ControlledCharacters node under
# this path
var CONTROLLED_CHARACTERS_PATH = ^"/root/GameRoot/Level/ControlledCharacters"

var _message_log = MessageLog.new()

# Navigation mesh should be rebaked when emitted
signal rebake_navigation_mesh_request()

# Get global player state node if it exists
func player_state() -> PlayerState:
	return get_node(PLAYER_STATE_PATH)

# Get level's controlled characters node if it exists
func controlled_characters() -> ControlledCharacters:
	return get_node(CONTROLLED_CHARACTERS_PATH)

# Get level's controlled characters node if it exists
func message_log() -> MessageLog:
	return _message_log

# Function that should be called whenever contants of the
# navigation_mesh_source_group group changes.
func rebake_navigation_mesh():
	rebake_navigation_mesh_request.emit()
