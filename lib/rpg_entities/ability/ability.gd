# Base class for all abilities. Ability is an action character can take such as
# cast spell, attack with weapon.
class_name Ability
extends Resource

@export var id: String

@export var name: String

@export var icon: Texture2D

@export var projectile: AbilityProjectile
