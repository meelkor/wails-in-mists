## Label that should show tooltip on hover
class_name LabelLink
extends Label

var di := DI.new(self)

@onready var _tooltip_spawner := di.inject(TooltipSpawner) as TooltipSpawner

## Label's tooltip can be either defined by new rich tooltip content
@export var content: RichTooltip.Content

## Or any resource that implements the get_tooltip_content such as Ability and
## many other entities.
@export var source: Resource


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(_mouse_entered)
	mouse_exited.connect(_mouse_exited)


func _mouse_entered() -> void:
	if source:
		_tooltip_spawner.open_for_entity(self, source)
	elif content:
		_tooltip_spawner.open_tooltip(self, content)


func _mouse_exited() -> void:
	_tooltip_spawner.close_tooltip()


func _gui_input(event: InputEvent) -> void:
	var btn := event as InputEventMouseButton
	if btn and btn.pressed and btn.button_index == MOUSE_BUTTON_RIGHT:
		if source:
			_tooltip_spawner.open_static_for_entity(source)
		elif content:
			_tooltip_spawner.open_static_tooltip(content)

