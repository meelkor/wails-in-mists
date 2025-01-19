## Implementation of SlotButton for button with single slot icon
extends SlotButton

@onready var _vbox := %VBoxContainer as VBoxContainer
@onready var _empty_label := %EmptyLabel as Label

var _shader: ShaderMaterial:
	get:
		return material


func _ready() -> void:
	super._ready()
	material = material.duplicate()


func _process(_delta: float) -> void:
	_shader.set_shader_parameter("size", size)


## Update content based on current hover state
func _update_hover(hover: bool) -> void:
	_shader.set_shader_parameter("hover_weight", 1.0 if hover else 0.0)


## Update content based on currently inserted entity.
func _update_entity(e: Slottable) -> void:
	# TODO: make disabled private and always read it from container's state?
	# that requires turn actions to be stored in character tho, so ability bar
	# can have info about available actions
	var btn_disabled := disabled or container.is_disabled(entity)
	_shader.set_shader_parameter("brightness", 1.0 if e and not btn_disabled else 0.4)
	# for now hardcoded for talents
	var pack := e as TalentPack
	Utils.Nodes.clear_children(_vbox)
	if pack:
		for line in pack.get_summary():
			var label := Label.new()
			label.text = line
			if btn_disabled:
				label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
			_vbox.add_child(label)
		_empty_label.visible = false
	else:
		_empty_label.visible = true


## todo: create some icon that represents talent back when dragged
func _start_drag() -> Control:
	return _vbox.duplicate()


func _end_drag() -> void:
	pass
