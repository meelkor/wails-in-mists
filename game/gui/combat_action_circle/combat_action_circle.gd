@tool
extends TextureRect

var di := DI.new(self)

@onready var _tooltip_spawner := di.inject(TooltipSpawner) as TooltipSpawner

@export var attribute: CharacterAttribute:
	set(v):
		attribute = v
		if is_inside_tree():
			_update_content()

@export_range(0, 1, 0.01) var used: float = 0.0:
	set(v):
		used = v
		if is_inside_tree():
			_update_content()

@export var preview: bool = false:
	set(v):
		preview = v
		if is_inside_tree():
			_update_content()

@export var tooltip_disabled := false


func _init() -> void:
	material = material.duplicate()


func _ready() -> void:
	_update_content()
	if not tooltip_disabled:
		var tooltip: RichTooltip.Content
		if attribute:
			var attr_path := attribute.resource_path
			tooltip = RichTooltip.create_generic_tooltip("[[%s]] action" % attr_path, "Represents combat action gained by sufficient [[%s]] attribute level. First action is gained at 2nd attribute level and another at 5th level. Each action can be used only once per turn." % attr_path)
		else:
			tooltip = RichTooltip.create_generic_tooltip("Move action", "Represents basic action which is automatically used when character starts walking during a combat turn. Alternatively the action can be used to drink a potion or to cast an abilities that requires the Move action. All characters have exactly one Move action.")
		tooltip.source = self
		_tooltip_spawner.register_tooltip(self, tooltip, TooltipSpawner.Axis.Y)


func _update_content() -> void:
	var sm := material as ShaderMaterial
	if attribute:
		sm.set_shader_parameter("offset", attribute.atlas_position + 1)
	else:
		sm.set_shader_parameter("offset", 1)
	sm.set_shader_parameter("used_ratio", used)
	sm.set_shader_parameter("saturation", 0.25 if preview else 1.0)
