extends Control

const SCREEN_MARGIN = Vector2(16, 16)
const MAX_WIDTH := 400

var _current_tooltip: Node

var _opening_tooltip_for: Object

var _hiding_tooltip: Node

enum Axis {
	X = 0,
	Y = 1,
}


## Try to open tooltip node for given entity if it provides the
## make_tooltip_content method and open it near source_node's position.
func open_for_entity(source_node: Control, entity: Object, axis: Axis = Axis.X) -> void:
	if entity.has_method("make_tooltip_content"):
		var content := entity.call("make_tooltip_content") as RichTooltip.Content
		if content:
			open_tooltip(source_node, content, axis)


## Open given tooltip near the given source node. Opening is delayed a little
## if there is not tooltip already open.
func open_tooltip(source_node: Control, content: RichTooltip.Content, axis: Axis = Axis.X) -> void:
	if not _current_tooltip:
		if _opening_tooltip_for != content.source:
			_opening_tooltip_for = content.source
			await get_tree().create_timer(0.35).timeout
			if _opening_tooltip_for == content.source and is_instance_valid(source_node):
				_open_tooltip_now(source_node, content, axis)
			if _opening_tooltip_for == content.source:
				_opening_tooltip_for = null
	else:
		_open_tooltip_now(source_node, content, axis)


## Close currently open tooltip after short while
func close_tooltip() -> void:
	_hiding_tooltip = _current_tooltip
	_opening_tooltip_for = null
	await get_tree().create_timer(0.1).timeout
	if _hiding_tooltip == _current_tooltip:
		_close_tooltip_now()


## Force close current tooltip right now
func _close_tooltip_now() -> void:
	if _current_tooltip:
		remove_child(_current_tooltip)
		_current_tooltip = null


## Force open current tooltip right now
func _open_tooltip_now(source_node: Control, content: RichTooltip.Content, axis: Axis = Axis.X) -> void:
	var rich_tooltip := preload("res://gui/rich_tooltip/rich_tooltip.tscn").instantiate() as RichTooltip
	# Hide the tooltip before it gets correctly resized, but using visible =
	# false results in wrapped text having incorrect size
	rich_tooltip.position = Vector2i(-1000, -1000)
	rich_tooltip.content = content
	add_child(rich_tooltip)
	# Check whether tooltip has some long wrapped text, if so increase its
	# width to MAX_WIDTH since I haven't found any native way to enformace
	# max_width
	for richtext: RichTextLabel in rich_tooltip.find_children("", "RichTextLabel", true, false):
		if richtext.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART and richtext.text.length() > 70:
			rich_tooltip.custom_minimum_size.x = MAX_WIDTH
			break
	# Didn't find a way to force size recalculation after its content (label's
	# text) changed, so we need to wait a frame (or two because of the
	# autowrapped text) before displaying it. todo: maybe fire some
	# notification? :thinking:
	await get_tree().process_frame
	await get_tree().process_frame
	# todo: I hate that we even need to check it here, improve the delayed
	# tooltip opening, so it doesn't happen at all when source node removed.
	if not is_instance_valid(source_node):
		remove_child(rich_tooltip)
		return
	# rich_tooltip.visible = true
	var src_pos := source_node.global_position
	var src_size := source_node.size
	var new_pos := Vector2()
	var screen_center := size / 2
	if axis == Axis.X:
		new_pos.y = src_pos.y + src_size.y / 2 - rich_tooltip.size.y / 2
		new_pos.x = src_pos.x - rich_tooltip.size.x if src_pos.x > screen_center.x else src_pos.x + src_size.x
	else:
		new_pos.x = src_pos.x + src_size.x / 2 - rich_tooltip.size.x / 2
		new_pos.y = src_pos.y - rich_tooltip.size.y if src_pos.y > screen_center.y else src_pos.y + src_size.y
	new_pos = new_pos.clamp(SCREEN_MARGIN, size + rich_tooltip.size - SCREEN_MARGIN)
	if _current_tooltip:
		remove_child(_current_tooltip)
	rich_tooltip.position = new_pos
	_current_tooltip = rich_tooltip
	_hiding_tooltip = null
