@icon("res://class_icons/base_level.svg")
class_name BaseLevel
extends Node

@export var level_name = "Base Level"

func _ready() -> void:
	global.message_log().system("Entered %s" % level_name)

func spawn_playable_characters(characters: Array[PlayableCharacter]):
	var spawn_position = Vector3($Spawn.position);
	$LevelCamera.move_to(spawn_position)
	# TODO: parent should provide the characters to us instead of us taking it
	# from state, since state contains ALL characters, not just those selected
	# for on current level
	for character in characters:
		var model = preload("res://models/human_female.tscn").instantiate()
		var ctrl = preload("res://scenes/character_controller.tscn").instantiate()
		ctrl.setup(character, model)
		$ControlledCharacters.add_character(ctrl)
		ctrl.position = spawn_position
		spawn_position -= Vector3(0.8, 0, 0.8)

	$RustyFow.setup(_create_terrain_aabb())
	$ControlledCharacters.position_changed.connect(_on_controlled_characters_position_changed)
	$LevelGui.set_characters(characters)

# Create AABB of all terrain meshes combined baking in their 3D translation
func _create_terrain_aabb() -> AABB:
	var nodes = find_children("", "MeshInstance3D") as Array[MeshInstance3D]
	var terrain_aabb: AABB
	for node in nodes:
		var naabb = node.get_aabb()
		# todo: also factor in rotation and scale to get the actual new aabb
		var translated_aabb = AABB(naabb.position + node.global_position, naabb.size)
		if !terrain_aabb:
			terrain_aabb = translated_aabb
		else:
			terrain_aabb = terrain_aabb.merge(translated_aabb)
	return terrain_aabb


func _on_controlled_characters_position_changed(positions) -> void:
	$RustyFow.update(positions)
