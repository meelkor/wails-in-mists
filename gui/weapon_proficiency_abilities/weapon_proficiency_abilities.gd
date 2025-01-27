extends HBoxContainer

const TypeStrip = preload("res://gui/type_strip/type_strip.gd")

var di := DI.new(self)

@onready var _tooltip_spawner := di.inject(TooltipSpawner) as TooltipSpawner

@export var weapon: ItemWeapon


func _ready() -> void:
	var strips: Array[TypeStrip] = [
		%TypeL1Strip as TypeStrip,
		%TypeL2Strip as TypeStrip,
		%TypeL3Strip as TypeStrip,
	]
	var ctx := di.inject(TooltipContext) as TooltipContext
	if ctx.character:
		var prof := ctx.character.get_proficiency(weapon.type)
		for lv in range(0, 3):
			if prof <= lv:
				strips[lv].disabled = true
			# todo: after weapon types are made into resources, use their
			# tooltip?
			_tooltip_spawner.register_tooltip(strips[lv], load("res://game_resources/terms/term_prof_l%s.tres" % str(lv + 1)))
