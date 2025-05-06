## Simply displays buff icon. Shows tooltip on hover.
extends PanelContainer

var di := DI.new(self)

@onready var _tooltip_spawner := di.inject(TooltipSpawner) as TooltipSpawner

@export var buff: Buff

@export var onset: BuffOnset

@export var count: int = 1

@onready var label := $Label as Label


func _ready() -> void:
	var style := StyleBoxTexture.new()
	style.texture = buff.icon
	if count > 1:
		label.text = str(count)
	else:
		label.visible = false
	add_theme_stylebox_override("panel", style)

	_tooltip_spawner.register_tooltip(self, buff, TooltipSpawner.Axis.X)
