extends MarginContainer

## Whether the panel should listen to prompts and display them
@export var prompts_enabled: bool

## Whether the panel should listen to regular messages and display them
@export var messages_enabled: bool

## Number of messages to read from history when the node is added to the scene.
@export var history: int = 0

@onready var _scroll_container := %ScrollContainer as ScrollContainer
@onready var _message_holder := %MessageHolder as VBoxContainer

func _ready() -> void:
	var msg_log := global.message_log() as MessageLog
	msg_log.message_received.connect(_create_message_label)
	msg_log.prompt_requested.connect(_create_message_prompt)
	for msg in msg_log.get_latest(history):
		_create_message_label(msg)


func _create_message_label(msg: MessageLogItem) -> void:
	var label := RichTextLabel.new()
	var msg_text := msg.text
	if msg.text_color:
		msg_text = "[color=#%s]%s[/color]" % [msg.text_color.to_html(), msg_text]
	if msg.name:
		msg_text = "[color=#%s]%s[/color]: %s" % [msg.name_color.to_html(), msg.name, msg_text]

	label.bbcode_enabled = true
	label.text = msg_text
	label.fit_content = true
	label.scroll_active = false
	_message_holder.add_child(label)
	_scroll_to_bottom()


func _create_message_prompt(prompt: MessageLog.Prompt) -> void:
	var buttons: Array[LinkButton]
	for i in range(prompt.options.size()):
		var answer_nr := i + 1
		var option := prompt.options[i]
		var label := LinkButton.new()
		label.text = "%s. %s" % [answer_nr, option.text]
		_message_holder.add_child(label)
		buttons.append(label)
		label.shortcut = Utils.get_action_shortcut("answer_%s" % answer_nr)
		label.pressed.connect(func () -> void:
			for button in buttons:
				_message_holder.remove_child(button)
			prompt.answer.emit(i)
		)
	_scroll_to_bottom()


func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	_scroll_container.set_deferred("scroll_vertical", 10000000)
