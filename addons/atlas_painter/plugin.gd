## Main plugin script which takes care of showing/hiding the dock when the
## atlas node is selected and the painting itself
@tool
extends EditorPlugin

const AtlasPainterDock := preload("./atlas_painter_dock.tscn")

var _dock: Control

var _edited_material: AtlasMaterial

## Painting in progress (button is bressed)
var _painting := false
## Whether any pixel was changed since last save
var _painted := false

## Last painted px, used to control "brush repeat"
var _last_px = Vector2i.ZERO

var _config: AtlasPainterConfig = null

func _enter_tree():
	_dock = AtlasPainterDock.instantiate()
	_dock.visible = false
	_dock.reset.connect(_reset_atlas_map)


func _exit_tree():
	if _dock:
		if _dock.visible:
			remove_control_from_docks(_dock)
		_dock.queue_free()


func _make_visible(vis: bool):
	if not _dock.visible and vis:
		add_control_to_dock(DockSlot.DOCK_SLOT_RIGHT_BL, _dock)
		_dock.visible = true
	elif _dock.visible and not vis:
		remove_control_from_docks(_dock)
		_dock.visible = false


func _handles(object: Object) -> bool:
	return object is AtlasMaterial


func _edit(object: Object) -> void:
	var material := object as AtlasMaterial
	if material:
		_edited_material = material
		_config = AtlasPainterConfig.new(_edited_material)
		_dock.set_config(_config)
	else:
		_make_visible(false)


func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Paint", "EditorIcons")


## Draw the brush circle on the edited material on mouse move, and start the
## painting on click.
##
## Block most mouse events (nodes cannot be selected by clicking into viewport
## while AtlasMaterial is edited).
func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	var event_mouse_btn := event as InputEventMouseButton
	var event_mouse_mtn := event as InputEventMouseMotion
	if event_mouse_btn or event_mouse_mtn:
		var uv := sample_terrain_uv2(viewport_camera, event.position)
		if uv != Vector2.ZERO:
			_update_brush_position(uv)
			if event_mouse_btn and event_mouse_btn.button_index == MOUSE_BUTTON_LEFT:
				_painting = event.pressed
				_paint_onto_map(viewport_camera, uv)
				if not _painting and _painted:
					_painted = false
					if _edited_material:
						# todo: store undoredo action
						ResourceSaver.save(_edited_material.atlas_map)
				return EditorPlugin.AFTER_GUI_INPUT_STOP
			if event_mouse_mtn and _painting:
				_paint_onto_map(viewport_camera, uv)

	return EditorPlugin.AFTER_GUI_INPUT_PASS


## Update material with position where the brush circle should be rendered
func _update_brush_position(uv: Vector2) -> void:
	_edited_material.set_shader_parameter("brush_uv", uv)
	_edited_material.set_shader_parameter("brush_size", float(_config.brush_size) / 512) # todo - read size


## The actual updating of the material's map texture on given position with
## brush setting according to the config
func _paint_onto_map(camera: Camera3D, uv: Vector2) -> void:
	var map_img := _edited_material.atlas_map

	if _edited_material.atlas_map:
		var center := uv * map_img.get_width()
		var strength: float = 0
		var brush_size_sq = _config.brush_size ** 2
		var img = _edited_material.atlas_map
		var img_rect = Rect2i(Vector2i.ZERO, img.get_size())
		if center.distance_to(_last_px) > _config.brush_size / 4.0:
			# todo: use brush mask image instead??
			# todo: implement some randomness like Terrain3D does?
			for x in range(-_config.brush_size, _config.brush_size):
				for y in range(-_config.brush_size, _config.brush_size):
					var point := Vector2i(x, y)
					var real_point := center + Vector2(point)
					if img_rect.has_point(real_point):
						var paint_val = (1 - min(1, Vector2(point).length_squared() / brush_size_sq)) ** _config.brush_fade * _config.brush_strength
						var cl := img.get_pixelv(real_point)
						var sign: float = 1

						# Put the texture into the texture slot (x or y) with
						# lower mix ratio
						if cl.r8 == _config.texture:
							sign = -1
						elif cl.g8 == _config.texture:
							sign = 1
						else:
							if cl.b > 0.5:
								cl.r8 = _config.texture
								sign = -1
							else:
								cl.g8 = _config.texture
								sign = 1

						cl.b8 += paint_val * sign
						img.set_pixelv(real_point, cl)
			_last_px = center
		_painted = true
		_edited_material.atlas_map.emit_changed()


## Get UV2 value under the mouse cursor on the nearest terrain body. Returns
## zero vec2 in case no body is bound.
##
## Basically stolen from https://github.com/thefryscorer/GodotPaintDemo/blob/master/world.gd
## because I am a dummy
func sample_terrain_uv2(camera: Camera3D, mouse_pos: Vector2) -> Vector2:
	var origin := camera.project_ray_origin(mouse_pos)
	var end := origin + camera.project_ray_normal(mouse_pos) * 10000
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = Utils.get_collision_layer("terrain")
	var scn: Node3D = EditorInterface.get_edited_scene_root()
	var result := scn.get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		var body: StaticBody3D = result["collider"]
		var child := body.get_child(0) as MeshInstance3D
		if child and child.mesh:
			var inter_pos: Vector3 = result["position"] * body.global_transform
			var meshtool := MeshDataTool.new()
			meshtool.create_from_surface(child.mesh, 0)
			var face = result["face_index"]
			var v1 := meshtool.get_vertex(meshtool.get_face_vertex(face, 0))
			var v2 := meshtool.get_vertex(meshtool.get_face_vertex(face, 1))
			var v3 := meshtool.get_vertex(meshtool.get_face_vertex(face, 2))
			var bc := barycentric(inter_pos, v1, v2, v3)
			var uv1 := meshtool.get_vertex_uv2(meshtool.get_face_vertex(face, 0))
			var uv2 := meshtool.get_vertex_uv2(meshtool.get_face_vertex(face, 1))
			var uv3 := meshtool.get_vertex_uv2(meshtool.get_face_vertex(face, 2))
			return (uv2 * bc.x) + (uv3 * bc.y) + (uv1 * bc.z)
	return Vector2.ZERO


## Get barycentric coordinates for triangle abc, that can be used to project
## point from one triangle to another
func barycentric(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var v0 := b - a
	var v1 := c - a
	var v2 := p - a
	var d00 := v0.dot(v0)
	var d01 := v0.dot(v1)
	var d11 := v1.dot(v1)
	var d20 := v2.dot(v0)
	var d21 := v2.dot(v1)
	var denom := d00 * d11 - d01 * d01;
	var v := (d11 * d20 - d01 * d21) / denom;
	var w := (d00 * d21 - d01 * d20) / denom;
	var u := 1.0 - v - w;
	return Vector3(v, w, u)


func _reset_atlas_map():
	if _edited_material:
		if not _edited_material.atlas_map:
			_edited_material.atlas_map = Image.create_empty(512, 512, true, Image.FORMAT_RGBA8)
		_edited_material.atlas_map.fill(Color8(0, 0, 0, 0))
		_edited_material.atlas_map.emit_changed()
