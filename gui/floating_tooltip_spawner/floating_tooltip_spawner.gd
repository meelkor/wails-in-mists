extends Control

const SCREEN_MARGIN = Vector2(16, 16)

var _current_tooltip: Node

var _opening_tooltip: Node

var _hiding_tooltip: Node

enum FloatingTooltipAxis {
	X = 0,
	Y = 1,
}

### Public ###

## Open given tooltip near the given source node. Opening is delayed a little
## if there is not tooltip already open.
func open_tooltip(source_node: Control, tooltip_node: Node, axis: FloatingTooltipAxis = FloatingTooltipAxis.X):
	if not _current_tooltip:
		_opening_tooltip = tooltip_node
		await get_tree().create_timer(0.25).timeout
		if _opening_tooltip == tooltip_node:
			_open_tooltip_now(source_node, tooltip_node, axis)
	else:
		_close_tooltip_now()
		_open_tooltip_now(source_node, tooltip_node, axis)


## Close currently open tooltip after short while
func close_tooltip():
	_hiding_tooltip = _current_tooltip
	_opening_tooltip = null
	await get_tree().create_timer(0.1).timeout
	if _hiding_tooltip == _current_tooltip:
		_close_tooltip_now()


### Private ###

## Force close current tooltip right now
func _close_tooltip_now():
	if _current_tooltip:
		remove_child(_current_tooltip)
		_current_tooltip = null


## Force open current tooltip right now
func _open_tooltip_now(source_node: Control, tooltip_node: Node, axis: FloatingTooltipAxis = FloatingTooltipAxis.X):
	add_child(tooltip_node)
	# Didn't find a way to force size recalculation after its content (label's
	# text) changed, so we need to wait a frame before displaying it
	tooltip_node.visible = false
	await get_tree().process_frame
	tooltip_node.visible = true
	var src_pos = source_node.global_position
	var src_size = source_node.size
	var new_pos = Vector2()
	var screen_center = size / 2
	if axis == FloatingTooltipAxis.X:
		new_pos.y = src_pos.y + src_size.y / 2 - tooltip_node.size.y / 2
		new_pos.x = src_pos.x - tooltip_node.size.x if src_pos.x > screen_center.x else src_pos.x + src_size.x
	else:
		new_pos.x = src_pos.x + src_size.x / 2 - tooltip_node.size.x / 2
		new_pos.y = src_pos.y + src_size.y
	new_pos = new_pos.clamp(SCREEN_MARGIN, size + tooltip_node.size - SCREEN_MARGIN)
	tooltip_node.position = new_pos
	_current_tooltip = tooltip_node
	_hiding_tooltip = null
