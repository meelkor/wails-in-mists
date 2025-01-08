extends PanelContainer

@onready var _label := %Label as Label

@export var text: String:
	set(v):
		text = v
		if is_inside_tree():
			_label.text = v


func _ready() -> void:
	_label.text = text
