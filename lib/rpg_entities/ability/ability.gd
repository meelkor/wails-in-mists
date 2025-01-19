# Base class for all abilities. Ability is an action character can take such as
# cast spell, attack with weapon.
class_name Ability
extends Slottable

const CombatActionCircle := preload("res://gui/combat_action_circle/combat_action_circle.gd")
const COMBAT_ACTION_CIRCLE = preload("res://gui/combat_action_circle/combat_action_circle.tscn")

enum TargetType {
	SINGLE,
	AOE,
	AOE_BOUND,
	SELF,
}

enum TargetFilter {
	FRIENDLY,
	ENEMY,
	ALL,
}

@export var id: String

@export var name: String

@export var visuals: AbilityVisuals

@export var target_type: TargetType

@export var target_filter: TargetFilter = TargetFilter.ALL

## Range. Not applicable for TargetType SELF
@export var reach: float

## Not applicable for TargetType SINGLE
@export var aoe_size: float

## todo: consider making this into array so we can easily do
## [WeaponDamageEffect(), GrantStatus(a)]
@export var effect: AbilityEffect

@export var required_actions: Array[CharacterAttribute] = []

@export var traits: Array[TraitTerm] = []


func make_tooltip_content() -> RichTooltip.Content:
	var content := RichTooltip.Content.new()
	content.source = self
	content.title = "Ability"
	var header := AbilityTooltipHeader.new()
	header.ability = self
	content.blocks.append(header)
	var tags := RichTooltip.TagLine.new()
	tags.margin_top = 8
	for term in traits:
		var term_tag := RichTooltip.TagChip.new(term.name)
		term_tag.link = term.make_tooltip_content()
		tags.add(term_tag)
	if tags.tags.size() > 0:
		content.blocks.append(tags)
	return content


@warning_ignore("missing_tool")
class AbilityTooltipHeader:
	extends RichTooltip.TooltipBlock

	@export var ability: Ability


	func _render() -> Control:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var slottable_icon := preload("res://gui/slottable_icon/slottable_icon.tscn").instantiate() as SlottableIcon
		slottable_icon.icon = ability.icon
		row.add_child(slottable_icon)

		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		col.size_flags_horizontal |= Control.SIZE_EXPAND
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_child(RichTooltip.StyledLabel.new(ability.name).render(_spawner))
		var actions := HBoxContainer.new()
		for attr in ability.required_actions:
			var circle := COMBAT_ACTION_CIRCLE.instantiate() as CombatActionCircle
			circle.custom_minimum_size = Vector2(20, 20)
			circle.attribute = attr
			actions.add_child(circle)
		col.add_child(actions)

		row.add_child(col)
		return row
