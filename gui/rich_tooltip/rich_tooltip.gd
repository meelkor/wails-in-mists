@tool
class_name RichTooltip
extends Control

@export var content: Content:
	set(c):
		content = c
		if is_inside_tree():
			_create_content()

var _shader: ShaderMaterial

@onready var _main_vbox := %MainVBox as VBoxContainer


func _ready() -> void:
	_shader = (%TextureRect as TextureRect).material
	_update()
	if content:
		_create_content()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			_update()


func _update() -> void:
	if _shader:
		_shader.set_shader_parameter("size", size)


func _create_content() -> void:
	Utils.Nodes.clear_children(_main_vbox)
	for block in content.blocks:
		_main_vbox.add_child(block.render())


## Represents complete content of the tooltip including all the text,
## hyperlinks and whatnow.
class Content:
	extends Resource

	@export var title: String
	## Components used as lines of content in the tooltip
	@export var blocks: Array[TooltipBlock]
	## For whatever object the tooltip was created
	var source: Variant


## Abstract class representing single row in the tooltip
class TooltipBlock:
	extends Resource


	## Create control node that should be displayed in the row
	func render() -> Control:
		return Control.new()


class TooltipHeader:
	extends TooltipBlock

	@export var icon: Texture2D
	@export var label: StyledLabel
	@export var sublabel: StyledLabel


	func render() -> Control:
		# todo: maybe make into scene that gets loaded here?
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var slottable_icon := preload("res://gui/slottable_icon/slottable_icon.tscn").instantiate() as SlottableIcon
		slottable_icon.icon = icon
		row.add_child(slottable_icon)

		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_child(label.render())
		if sublabel:
			col.add_child(sublabel.render())
		row.add_child(col)

		return row


## Helper for quickly creating Label inside tooltip with desired text and
## color.
##
## todo: should support hyperlinks to other RichTooltip
class StyledLabel:
	extends TooltipBlock

	@export var text: String
	@export var color: Color = Config.Palette.TOOLTIP_TEXT


	func _init(i_text: String = "", i_color: Color = Config.Palette.TOOLTIP_TEXT) -> void:
		text = i_text
		color = i_color


	func render() -> Control:
		var label := Label.new()
		label.text = text
		if color != Config.Palette.TOOLTIP_TEXT:
			label.add_theme_color_override("font_color", color)
		return label
