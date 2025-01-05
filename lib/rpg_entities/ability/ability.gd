# Base class for all abilities. Ability is an action character can take such as
# cast spell, attack with weapon.
class_name Ability
extends Slottable

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

@export var ends_turn: bool = false


func make_tooltip_content() -> RichTooltip.Content:
	var content := RichTooltip.Content.new()
	content.source = self
	content.title = "Item"
	var header := RichTooltip.TooltipHeader.new()
	header.label = RichTooltip.StyledLabel.new(name)
	header.icon = icon
	content.blocks.append(header)
	return content
