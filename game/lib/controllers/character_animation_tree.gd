@tool
class_name CharacterAnimationTree
extends AnimationTree

@export var idle_animation: StringName = &""
@export var run_animation: StringName = &""
@export var defend_animation: StringName = &""
@export var idle_combat_animation: StringName = &""
@export var walk_combat_animation: StringName = &""
@export var ready_weapon_animation: StringName = &""
@export var melee_1h_attack_animation: StringName = &""
@export var cast_self_animation: StringName = &""
@export var throw_animation: StringName = &""
@export var hit_animation: StringName = &""


func _enter_tree() -> void:
	var root := preload("res://lib/controllers/character_animation_tree_template.tres").duplicate(true) as AnimationNodeBlendTree
	tree_root = root
	_set_animation_node("Idle", idle_animation)
	_set_animation_node("Run", run_animation)
	_set_animation_node("Defend", defend_animation)
	_set_animation_node("IdleCombat", idle_combat_animation)
	_set_animation_node("WalkCombat", walk_combat_animation)
	_set_animation_node("ReadyWeapon", ready_weapon_animation)
	_set_animation_node("Melee1hAttack", melee_1h_attack_animation)
	_set_animation_node("CastSelf", cast_self_animation)
	_set_animation_node("Throw", throw_animation)
	_set_animation_node("Hit", hit_animation)


func _ready() -> void:
	set("parameters/State/transition_request", "IDLE")
	set("parameters/DefendState/transition_request", "DEFAULT")


func _validate_property(property: Dictionary) -> void:
	if property["name"] == "tree_root" or (property["name"] as StringName).begins_with("parameter"):
		property.usage = PROPERTY_USAGE_RESOURCE_NOT_PERSISTENT | PROPERTY_USAGE_NO_INSTANCE_STATE
		property.usage = 0


func _set_animation_node(node_name: StringName, animation_name: StringName) -> void:
	var player := get_node(anim_player) as AnimationPlayer
	if animation_name && player.has_animation(animation_name):
		var animation_node := (tree_root as AnimationNodeBlendTree).get_node(node_name) as AnimationNodeAnimation
		var animation := player.get_animation(animation_name)
		animation_node.animation = animation_name
	elif animation_name == "Idle":
		print("sad")
		var charscn := Utils.Nodes.find_parent_by_type(self, "CharacterController") as CharacterController
		push_error("Character %s doesn't even have Idle animation" % charscn.character.name)
