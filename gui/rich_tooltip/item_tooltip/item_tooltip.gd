extends MarginContainer

@export var item: Item:
	set(new_item):
		item = new_item
		_update_content()


func _ready() -> void:
	_update_content()


func _update_content() -> void:
	if item:
		visible = true
		%ItemNameLabel.text = item.name
		%ItemSubLabel.text = item.get_heading()
		%ItemSlotButton.icon = item.icon
	else:
		visible = false