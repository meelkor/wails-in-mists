# Main hub for storing and sending messages in the message log. Messages can be
# sent at any time but the message log may not always be visible.

extends Node
class_name MessageLog

var messages: Array[MessageLogItem]

var SYSTEM_COLOR = Color.from_string("#A3A3A3", Color.RED);
var WARNING_COLOR = Color.from_string("#F26B4E", Color.RED);

# Signal emitted whenever new message was sent.
signal message_received(msg: MessageLogItem)

# Display dialogue line
func dialogue(char_name: String, color: Color, text: String):
	var msg = MessageLogItem.new()
	msg.name = char_name
	msg.name_color = color
	msg.text = text
	send_message(msg)

# Display less visible info text
func system(text: String):
	var msg = MessageLogItem.new()
	msg.text = text
	msg.text_color = SYSTEM_COLOR
	send_message(msg)

# Display warning text
func warning(text: String):
	var msg = MessageLogItem.new()
	msg.text = text
	msg.text_color = WARNING_COLOR
	send_message(msg)

# Get {num} latest messages
func get_latest(num: int) -> Array[MessageLogItem]:
	return messages.slice(-num)

# Store given message instance and notify subscribers
func send_message(item: MessageLogItem):
	messages.append(item)
	message_received.emit(item)
