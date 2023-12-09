# Singleton service node available under as `global` used to access some
# well-known nodes such as player object, so we don't need to write the whole
# path everytime we need to access it from somewhere.

extends Node
class_name Global

# Player state if exists should always be found under this path. Player state
# is expected to exist only after new game is created or existing loaded.
const PLAYER_STATE_PATH = ^"/root/GameRoot/PlayerState"

# If level is loaded, it should always have the ControlledCharacters node under
# this path
const CONTROLLED_CHARACTERS_PATH = "/root/GameRoot/Level/ControlledCharacters"

# Should always be available... probably dunno about main menu / char creation
const MESSAGE_LOG_PATH = "/root/GameRoot/MessageLog"

# Get global player state node if it exists
func player_state() -> PlayerState:
	return get_node(PLAYER_STATE_PATH)

# Get level's controlled characters node if it exists
func controlled_characters() -> ControlledCharacters:
	return get_node(CONTROLLED_CHARACTERS_PATH)

# Get level's controlled characters node if it exists
func message_log() -> MessageLog:
	return get_node(MESSAGE_LOG_PATH)
