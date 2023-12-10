class_name TerrainController
extends Node

signal terrain_clicked(pos: Vector3)

var selecting_from: Vector2 = Vector2.ZERO

func _ready():
	global.navigation_obstacles_changed.connect(_on_nav_obstacles_changed)

# Check current obstacles and rebake the navigation mesh. It would be probably
# better to manually modify the polygons, but that sounds like a lot of work
# and this works somewhat fine so far
#
# TODO: currently for any obstacle a human-sized hole in navigation map is
#   created, which won't be enough in the future.
func _on_nav_obstacles_changed():
	var nav_region = find_child("NavigationRegion3D") as NavigationRegion3D
	var existing_meshes = get_tree().get_nodes_in_group("baked_navigation_obstacle_mesh")
	var obstacles = get_tree().get_nodes_in_group(KnownGroups.BAKED_NAVIGATION_OBSTACLE)

	for mesh in existing_meshes:
		nav_region.remove_child(mesh)

	for obstacle in obstacles:
		if obstacle is CharacterBody3D:
			var mesh = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size.x = 0.05
			box.size.z = 0.05
			box.size.y = 6
			mesh.mesh = box
			mesh.visible = false
			mesh.position = obstacle.global_position
			mesh.add_to_group("baked_navigation_obstacle_mesh")
			nav_region.add_child(mesh)
	# Run on main thread so if the rebaking cause is initiated moviement the
	# first pathfinding is already on the updated mesh
	nav_region.bake_navigation_mesh(false)

func _on_terrain_input_event(_camera, event: InputEvent, position: Vector3, _normal, _idx):
	if event is InputEventMouseButton:
		if event.is_released():
			if event.button_index == MOUSE_BUTTON_RIGHT:
				terrain_clicked.emit(position)
