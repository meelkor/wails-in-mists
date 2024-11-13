## Main hub for storing and sending messages in the message log. Messages can be
## sent at any time but the message log may not always be visible.

class_name MessageLog
extends Resource

@export var messages: Array[MessageLogItem] = []


## Signal emitted whenever new message was sent.
signal message_received(msg: MessageLogItem)


## Display dialogue line
func dialogue(char_name: String, color: Color, text: String) -> void:
	var msg := MessageLogItem.new()
	msg.name = char_name
	msg.name_color = color
	msg.text = text
	send_message(msg)


## Display less visible info text
func system(text: String) -> void:
	var msg := MessageLogItem.new()
	msg.text = text
	msg.text_color = Config.Palette.SYSTEM
	send_message(msg)


## Display warning text
func warning(text: String) -> void:
	var msg := MessageLogItem.new()
	msg.text = text
	msg.text_color = Config.Palette.WARNING
	send_message(msg)


## Get {num} latest messages
func get_latest(num: int) -> Array[MessageLogItem]:
	return messages.slice(-num)


## Store given message instance and notify subscribers
func send_message(item: MessageLogItem) -> void:
	messages.append(item)
	message_received.emit(item)
