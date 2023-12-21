# Base class for all abilities. Ability is an action character can take such as
# cast spell, attack with weapon.
class_name Ability
extends Resource

enum TargetType {
	SINGLE,
	AOE,
	AOE_BOUND,
	SELF,
}

@export var id: String

@export var name: String

@export var icon: Texture2D

@export var projectile: EffectVisuals

@export var target_type: TargetType

# Range. Not applicable for TargetType SELF
@export var reach: float

# Not applicable for TargetType SINGLE
@export var aoe_size: float

@export var ability_effect: AbilityEffect
