# Container which limits the one child's size to given values. When value not
# given, the dimension is unrestricted and the child is set to fill the parent
# in that dimension. Layou shrink begin/center/end options are respected. Fill
# sizings are ignored as they do not make sense in this context.
@tool
extends Container

# Max width in pixels or vw in viewport units are enabled
@export var max_width: int = 0:
	set(v):
		max_width = v
		if is_inside_tree():
			_update_child_size()

# Max height in pixels or vh in viewport units are enabled
@export var max_height: int = 0:
	set(v):
		max_height = v
		if is_inside_tree():
			_update_child_size()

@export var viewport_units: bool = false:
	set(v):
		viewport_units = v
		if is_inside_tree():
			_update_child_size()

func _ready() -> void:
	_init_current_child()
	child_entered_tree.connect(func (_n): _update_child_size())

func _notification(what):
	match what:
		NOTIFICATION_RESIZED:
			_update_child_size()

func _update_child_size():
	var child = _get_the_child()
	if child:
		var viewport_size = get_viewport().get_window().size
		var real_max_width = viewport_size.x / 100 * max_width if viewport_units else max_width
		var real_max_height = viewport_size.y / 100 * max_height if viewport_units else max_height

		child.size.x = min(real_max_width, size.x) if real_max_width > 0 else size.x
		child.size.y = min(real_max_height, size.y) if real_max_height > 0 else size.y

		if child.size_flags_horizontal & SIZE_SHRINK_END:
			child.position.x = size.x - child.size.x
		if child.size_flags_vertical & SIZE_SHRINK_END:
			child.position.y = size.y - child.size.y
		if child.size_flags_horizontal & SIZE_SHRINK_BEGIN:
			child.position.x = 0
		if child.size_flags_vertical & SIZE_SHRINK_BEGIN:
			child.position.y = 0
		if child.size_flags_horizontal & SIZE_SHRINK_CENTER:
			child.position.x = round((size.x - child.size.x) / 2)
		if child.size_flags_vertical & SIZE_SHRINK_CENTER:
			child.position.y = round((size.y - child.size.y) / 2)

func _init_current_child() -> void:
	var child = _get_the_child()
	if child:
		_update_child_size()
		child.size_flags_changed.connect(func (): _update_child_size())


func _get_the_child() -> Control:
	return get_child(0)

func _get_configuration_warnings() -> PackedStringArray:
	if get_child_count() != 1:
		return ["Limiter expects exactly one child"]
	else:
		return []
