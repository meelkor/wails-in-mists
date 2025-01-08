@tool
class_name RichTooltip
extends Control

var di := DI.new(self)

@onready var _tooltip_spawner := di.inject(TooltipSpawner) as TooltipSpawner

## Emitted when this tooltip should be moved to top
signal focused()

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
## When dragging in progress, it contains mouse global position of the initial
## mouse press
var _dragging_from: Vector2 = Vector2.ZERO
## Original position when dragging started
var _dragging_orig_pos: Vector2 = Vector2.ZERO

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
		var child := block.render(_tooltip_spawner)
		_main_vbox.add_child(child)


func _on_child_tooltip_requested(content_or_src: Object, source_node: Control, open_static: bool) -> void:
	var sub_content := content_or_src as Content
	if sub_content:
		if open_static:
			_tooltip_spawner.open_static_tooltip(sub_content)
		else:
			_tooltip_spawner.open_tooltip(source_node, sub_content)
	elif content_or_src:
		if open_static:
			_tooltip_spawner.open_static_for_entity(content_or_src)
		else:
			_tooltip_spawner.open_for_entity(source_node, content_or_src)
	else:
		_tooltip_spawner.close_tooltip()


func _gui_input(event: InputEvent) -> void:
	var btn := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	if btn:
		if btn.pressed:
			_dragging_from = btn.global_position
			_dragging_orig_pos = global_position
			if btn.button_index == MOUSE_BUTTON_LEFT:
				focused.emit()
			accept_event()
		else:
			_dragging_from = Vector2.ZERO
			accept_event()
	elif motion and _dragging_from != Vector2.ZERO:
		position = _sanitize_position(_dragging_orig_pos + motion.global_position - _dragging_from)
		accept_event()


func _sanitize_position(pos: Vector2) -> Vector2:
	var win_size := Vector2(get_window().size)
	return pos.clamp(Vector2.ZERO, win_size - size)


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

	## Source spawner provided by parent on render, so this tooltip block can
	## open another tooltip.
	var _spawner: TooltipSpawner

	## Create control node that should be displayed in the row
	func render(spawner: TooltipSpawner) -> Control:
		_spawner = spawner
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


	## Can be used by subclasses to quickly bing linked tooltip to given
	## control node.
	func _register_link(node: Control, link_content: Content) -> void:
		node.mouse_entered.connect(_spawner.open_tooltip.bind(node, link_content))
		node.mouse_exited.connect(_spawner.close_tooltip)
		node.gui_input.connect(_on_header_gui_input.bind(link_content))
		node.mouse_filter = Control.MOUSE_FILTER_PASS


	func _on_header_gui_input(event: InputEvent, link_content: Content) -> void:
		var btn := event as InputEventMouseButton
		if btn and btn.pressed and btn.button_index == MOUSE_BUTTON_RIGHT:
			_spawner.open_static_tooltip(link_content)


class TooltipHeader:
	extends TooltipBlock

	@export var icon: Texture2D
	@export var label: StyledLabel
	@export var sublabel: StyledLabel
	@export var icon_size: int = 0
	## Tooltip that should appear when hovering this block
	@export var link: Content


	func _render() -> Control:
		# todo: maybe make into scene that gets loaded here?
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var slottable_icon := preload("res://gui/slottable_icon/slottable_icon.tscn").instantiate() as SlottableIcon
		slottable_icon.icon = icon
		row.add_child(slottable_icon)
		if icon_size > 0:
			slottable_icon.custom_minimum_size = Vector2(icon_size, icon_size)

		var col := VBoxContainer.new()
		col.size_flags_horizontal |= Control.SIZE_EXPAND
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_child(label.render(_spawner))
		if sublabel:
			col.add_child(sublabel.render(_spawner))
		row.add_child(col)
		if link:
			_register_link(row, link)
		return row


## Helper for quickly creating Label inside tooltip with desired text and
## color.
##
## Supports links to other entities with tooltip using the [url] bbcode like
## [url=res://path/to.res]Text[url].
class StyledLabel:
	extends TooltipBlock

	@export var text: String
	@export var color: Color = Config.Palette.TOOLTIP_TEXT
	## Font size, -1 means default
	@export var size: int = -1
	@export var autowrap: bool = false

	var _hovered_resource: Object

	func _init(i_text: String = "", i_color: Color = Config.Palette.TOOLTIP_TEXT) -> void:
		text = i_text
		color = i_color


	func _render() -> Control:
		var label := RichTextLabel.new()
		if autowrap:
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		else:
			label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.bbcode_enabled = true
		label.fit_content = true
		# todo: generalize, we'll need it also outside tooltips such as
		# dialogue text.
		var short_path_regexp := RegEx.create_from_string("\\[\\[([\\w:]+)\\]\\]")
		while true:
			var ex := short_path_regexp.search(text)
			if ex:
				var short_path := ex.get_string(1)
				var res := ShortPath.load(short_path)
				# todo: standardize how plural etc. is stored in the resources
				var url_tag := "[url=%s]%s[/url]" % [res.resource_path, res.get("name") if res.get("name") else short_path]
				text = text.replace(ex.get_string(0), url_tag)
			else:
				break
		label.text = text
		if color != Config.Palette.TOOLTIP_TEXT:
			label.add_theme_color_override("default_color", color)
		if size != -1:
			label.add_theme_font_size_override("normal_font_size", size)
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		label.meta_hover_started.connect(_on_url_hover_started)
		label.meta_hover_ended.connect(_on_url_hover_ended)
		label.gui_input.connect(_on_label_gui_input)
		return label


	func _on_url_hover_started(path: String) -> void:
		var res := load(path)
		_hovered_resource = res
		_spawner.open_for_entity(TooltipSpawner.MOUSE_POSITION, res, TooltipSpawner.Axis.Y)


	func _on_url_hover_ended(_path: String) -> void:
		_hovered_resource = null
		_spawner.close_tooltip()


	## Little hacky way to detect right click on rich text url, since the
	## meta_clicked signal doesn't emit on right click. Also it fires before
	## gui_event so the tooltip focus happens after the new tooltip is opened.
	func _on_label_gui_input(e: InputEvent) -> void:
		var btn := e as InputEventMouseButton
		if btn and btn.pressed and _hovered_resource:
			_spawner.open_static_for_entity(_hovered_resource)


class TagChip:
	extends TooltipBlock

	@export var label: String
	@export var link: Content
	@export var color: Color
	# todo: icon


	func _init(i_label: String = "", i_color: Color = Config.Palette.TOOLTIP_TEXT) -> void:
		label = i_label
		color = i_color


	func _render() -> Control:
		const Tag := preload("res://gui/tag_chip/tag_chip.gd")
		var tag := preload("res://gui/tag_chip/tag_chip.tscn").instantiate() as Tag
		tag.text = label
		if link:
			_register_link(tag, link)
		return tag


class TagLine:
	extends TooltipBlock

	@export var tags: Array[TagChip]


	func add(tag: TagChip) -> void:
		tags.append(tag)


	func _render() -> Control:
		var row := HBoxContainer.new()
		for tag in tags:
			row.add_child(tag.render(_spawner))
		return row
