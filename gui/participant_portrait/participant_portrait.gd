extends HBoxContainer

const _default_stylebox = preload("./default_stylebox.tres")
const _active_stylebox = preload("./active_stylebox.tres")

var di := DI.new(self)

@onready var _combat: Combat = di.inject(Combat)

## Character to read portrait, HP and buffs for
@export var character: GameCharacter
## Whether the portrait should be highlighted
@export var active: bool = false

@onready var _portrait_panel := $FramePanel as PanelContainer
@onready var _frame_panel := %PortraitPanel as PanelContainer
@onready var _hp_bar := %ProgressBar as ProgressBar

var _portrait_stylebox := StyleBoxTexture.new()


func _ready() -> void:
	tooltip_text = character.name
	_portrait_stylebox.texture = character.get_portrait_texture()
	_portrait_panel.add_theme_stylebox_override("panel", _portrait_stylebox)
	_combat.state.changed.connect(_on_combat_state_change)
	if active:
		_frame_panel.add_theme_stylebox_override("panel", _active_stylebox)
	else:
		_frame_panel.add_theme_stylebox_override("panel", _default_stylebox)


func _on_combat_state_change() -> void:
	var max_hp := Ruleset.calculate_max_hp(character)
	_hp_bar.min_value = 0
	_hp_bar.max_value = max_hp
	_hp_bar.value = _combat.get_hp(character)
