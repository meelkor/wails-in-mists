@tool
class_name RichTooltip
extends Control

@export var content: Content:
	set(c):
		content = c
		if is_inside_tree():
			_create_content()

@export var alpha_threshold: float = 1.0:
	set(v):
		alpha_threshold = v
		if is_inside_tree():
			_update()

@export var border_color: Color = Color(0.2, 0.2, 0.2):
	set(v):
		border_color = v
		if is_inside_tree():
			_update()

var _shader: ShaderMaterial

@onready var _main_vbox := %MainVBox as VBoxContainer
@onready var _texture_rect := %TextureRect as TextureRect


func _ready() -> void:
	_texture_rect.material = _texture_rect.material.duplicate()
	_shader = _texture_rect.material
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
		_shader.set_shader_parameter("alpha_threshold", alpha_threshold)
		_shader.set_shader_parameter("border_color", border_color)


func _create_content() -> void:
	Utils.Nodes.clear_children(_main_vbox)
	for block in content.blocks:
		var child := block.render()
		child.owner = self
		_main_vbox.add_child(child)


## Represents complete content of the tooltip including all the text,
## hyperlinks and whatnow.
class Content:
	extends Resource

	@export var title: String
	## Components used as lines of content in the tooltip
	@export var blocks: Array[TooltipBlock]
	## For whatever object the tooltip was created
	var source: Variant


	## Merged given tooltip content into this content
	func append_content(other: Content) -> void:
		blocks.append_array(other.blocks)


## Abstract class representing single row in the tooltip
class TooltipBlock:
	extends Resource

	var margin_top: int = 0


	## Create control node that should be displayed in the row
	func render() -> Control:
		if margin_top > 0:
			var cont := MarginContainer.new()
			cont.add_theme_constant_override("margin_top", margin_top)
			cont.add_theme_constant_override("margin_left", 0)
			cont.add_theme_constant_override("margin_right", 0)
			cont.add_theme_constant_override("margin_bottom", 0)
			cont.add_child(_render())
			return cont
		else:
			return _render()


	func _render() -> Control:
		assert(false, "Rich tooltip block's render not implemented")
		return Control.new()


class TooltipHeader:
	extends TooltipBlock

	@export var icon: Texture2D
	@export var label: StyledLabel
	@export var sublabel: StyledLabel


	func _render() -> Control:
		# todo: maybe make into scene that gets loaded here?
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var slottable_icon := preload("res://gui/slottable_icon/slottable_icon.tscn").instantiate() as SlottableIcon
		slottable_icon.icon = icon
		row.add_child(slottable_icon)

		var col := VBoxContainer.new()
		col.size_flags_horizontal |= Control.SIZE_EXPAND
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
	## Font size, -1 means default
	@export var size: int = -1
	@export var autowrap: bool = false


	func _init(i_text: String = "", i_color: Color = Config.Palette.TOOLTIP_TEXT) -> void:
		text = i_text
		color = i_color


	func _render() -> Control:
		var label := RichTextLabel.new()
		if autowrap:
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		else:
			label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.fit_content = true
		label.text = text
		if color != Config.Palette.TOOLTIP_TEXT:
			label.add_theme_color_override("default_color", color)
		if size != -1:
			label.add_theme_font_size_override("normal_font_size", size)
		return label
