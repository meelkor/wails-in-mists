extends MarginContainer

@export var ref: ItemRef:
	set(new_item):
		ref = new_item
		if is_inside_tree():
			_update_content()


func _ready() -> void:
	_update_content()


func _update_content() -> void:
	if ref:
		visible = true
		(%ItemNameLabel as Label).text = ref.item.name
		(%ItemSubLabel as Label).text = ref.item.get_heading()
		(%EntityIcon as SlottableIcon).icon = ref.icon
	else:
		visible = false
