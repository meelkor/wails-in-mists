@icon("res://class_icons/base_level.svg")
class_name BaseLevel
extends Node

func _ready():
	# init testing scenario
	var game = get_parent() as GameRoot
	var spawn_position = Vector3($Spawn.position);
	$LevelCamera.force_set_position(spawn_position + Vector3(0, 0, 5))
	for _character in game.playable_characters:
		var model = preload("res://models/character-test.tscn").instantiate()
		var packed = preload("res://scenes/character_controller.tscn")
		var ctrl = packed.instantiate()
		ctrl.setup(model)
		$ControlledCharacters.add_character(ctrl)
		ctrl.position = spawn_position
		spawn_position -= Vector3(1.5, 0, 1.5)

	$RustyFow.setup(_create_terrain_aabb())
	$ControlledCharacters.position_changed.connect(_on_controlled_characters_position_changed)

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
	pass
	$RustyFow.update(positions)
