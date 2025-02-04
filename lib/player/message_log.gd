## Main hub for storing and sending messages in the message log. Messages can be
## sent at any time but the message log may not always be visible.
class_name MessageLog
extends Resource


## Create generic prompt that just require user to press continue
static func prompt_continue(last: bool = false) -> Prompt:
	return Prompt.new([PromptOption.new("End conversation." if last else "Continue...")])


@export var messages: Array[MessageLogItem] = []


## Signal emitted whenever new message was sent.
signal message_received(msg: MessageLogItem)

## Signal emitted whenever prompt is requested, active message log node should
## display it and report its result using the Prompt's signal
signal prompt_requested(prmpt: Prompt)


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


## Request user to select from one of the prompt's options
func prompt(content: Prompt) -> int:
	prompt_requested.emit(content)
	return await content.answer


## Get {num} latest messages
func get_latest(num: int) -> Array[MessageLogItem]:
	return messages.slice(-num)


## Store given message instance and notify subscribers
func send_message(item: MessageLogItem) -> void:
	messages.append(item)
	message_received.emit(item)


class Prompt:
	extends RefCounted

	signal answer(idx: int)

	var options: Array[PromptOption]


	func _init(opts: Array[PromptOption] = []) -> void:
		options = opts


class PromptOption:
	extends RefCounted

	var text: String

	var disabled: bool


	func _init(i_text: String, i_disabled: bool = false) -> void:
		text = i_text
		disabled = i_disabled
