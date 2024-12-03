## NavigationRegion3D which handles baking of the navigation mesh.
##
## It would be probably better to manually modify the polygons, but that sounds
## like a lot of work and this works somewhat fine so far.
extends NavigationRegion3D

var di := DI.new(self)

## Should only be true when not using Terrain3D since its script handles
## navmesh generation.
@export var auto_bake_navigation: bool = false


func _ready() -> void:
	if auto_bake_navigation:
		global.rebake_navigation_mesh_request.connect(bake_navigation_mesh.bind(true))
