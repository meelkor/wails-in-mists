## Utility class for creating meshes that should be used in @tool scenes to mark
## empty scene's position.
class_name EditorMeshBuilder
extends Object


## Create billboard mesh that should be added to the scene when in editor
static func make_editor_mesh(icon_path: String = "") -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.position.y += 0.03
	mesh_instance.cast_shadow = MeshInstance3D.SHADOW_CASTING_SETTING_OFF
	var qmesh: QuadMesh = QuadMesh.new()
	qmesh.size = Vector2(0.4, 0.4)
	qmesh.orientation = PlaneMesh.FACE_Y
	mesh_instance.mesh = qmesh
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	if icon_path.length() > 0:
		mat.albedo_texture = load(icon_path)
	mesh_instance.material_override = mat
	return mesh_instance
