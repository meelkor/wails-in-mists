class_name TerrainController
extends Node

signal terrain_clicked(pos: Vector3)

var selecting_from: Vector2 = Vector2.ZERO

func _ready():
	global.rebake_navigation_mesh_request.connect(_on_nav_obstacles_changed)

# Rebake the navigation mesh. It would be probably better to manually modify
# the polygons, but that sounds like a lot of work and this works somewhat fine
# so far.
func _on_nav_obstacles_changed():
	var nav_region = find_child("NavigationRegion3D") as NavigationRegion3D
	# Run on main thread so if the rebaking cause is initiated moviement the
	# first pathfinding is already on the updated mesh
	nav_region.bake_navigation_mesh(false)

func _on_terrain_input_event(_camera, event: InputEvent, position: Vector3, _normal, _idx):
	if event is InputEventMouseButton:
		if event.is_released():
			if event.button_index == MOUSE_BUTTON_RIGHT:
				terrain_clicked.emit(position)
