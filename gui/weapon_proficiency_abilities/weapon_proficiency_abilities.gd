extends HBoxContainer

const TypeStrip = preload("res://gui/type_strip/type_strip.gd")

var di := DI.new(self)

@onready var _tooltip_spawner := di.inject(TooltipSpawner) as TooltipSpawner

## Type for which to display info and abilities
@export var type: WeaponType


func _ready() -> void:
	var strips: Array[TypeStrip] = [
		%TypeL1Strip as TypeStrip,
		%TypeL2Strip as TypeStrip,
		%TypeL3Strip as TypeStrip,
	]
	var ability_containers: Array[BoxContainer] = [
		%L1Abilities as BoxContainer,
		%L2Abilities as BoxContainer,
		%L3Abilities as BoxContainer,
	]
	var categories: Array[__CombatCategory] = [
		type.family.style,
		type.family,
		type,
	]
	var abilities: Array[Array] = [
		type.l1_abilities,
		type.l2_abilities,
		type.l3_abilities,
	]
	var ctx := di.inject(TooltipContext) as TooltipContext
	if ctx.character:
		var prof := ctx.character.get_proficiency(type)
		for lv in range(0, 3):
			strips[lv].text = categories[lv].name
			strips[lv].disabled = prof < lv + 1
			_tooltip_spawner.register_tooltip(strips[lv], categories[lv])
			for ability: Ability in abilities[lv]:
				# todo: make into control node
				var ability_line := RichTooltip.TooltipHeader.new()
				# todo: dim as "disabled" when character cannot cast
				ability_line.icon = ability.icon
				ability_line.icon_size = 32
				ability_line.link = ability.make_tooltip_content()
				ability_containers[lv].add_child(ability_line.render(_tooltip_spawner))
