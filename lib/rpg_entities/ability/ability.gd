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

## Decides whether ability can be caster when character has offhand equipment
## or two-handed weapon without the "free hand casting" tag (which doesn't
## exist yet).
@export var requires_free_hand: bool = false


func make_tooltip_content() -> RichTooltip.Content:
	var content := RichTooltip.Content.new()
	content.source = self
	content.title = "Ability"
	var header := RichTooltip.TooltipHeader.new()
	header.label = RichTooltip.StyledLabel.new(name)
	header.icon = icon
	content.blocks.append(header)
	var tags := RichTooltip.TagLine.new()
	tags.margin_top = 8
	if requires_free_hand:
		# todo: where to store "well known" tags like this? Maybe those
		# shouldn't be bool flags but resources of their own? AbilityTrait? or
		# maybe Trait in general so special class doesn't need to exist for
		# item traits such as "Hand-casting".
		var hand_tag := RichTooltip.Tag.new("Hand-casted")
		hand_tag.link = RichTooltip.create_text_tooltip("Hand-casted", "To cast this ability the character needs to have a free hand. Character must not have any off-hand and weapon needs to be one-handed or two-handed with the Hand-casting trait such as Staves.")
		tags.add(hand_tag)
	if ends_turn:
		var end_turn := RichTooltip.Tag.new("Ends turn")
		end_turn.link = RichTooltip.create_text_tooltip("Ends turn", "Casting this ability ends current turn in ongoing combat and no other action can be taken afterwards.")
		tags.add(end_turn)
	if tags.tags.size() > 0:
		content.blocks.append(tags)
	return content
