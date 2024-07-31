extends VBoxContainer

var di = DI.new(self)

@onready var _combat: Combat = di.inject(Combat)

@onready var _hp_label = $HpLabel

@export var character: GameCharacter

@onready var _base_min_size: Vector2 = $PortaitImage.custom_minimum_size

### Lifecycle ###

func _ready() -> void:
	tooltip_text = character.name


func _process(_delta: float) -> void:
	var hp = _combat.get_hp(character)
	# todo: should be probably precomputed
	var max_hp = Ruleset.calculate_max_hp(character)
	_hp_label.text = "%s / %s" % [hp, max_hp]
	if _combat.get_active_character() == character:
		$PortaitImage.custom_minimum_size = _base_min_size * 1.28
	else:
		$PortaitImage.custom_minimum_size = _base_min_size