shader_type spatial;
render_mode shadows_disabled,cull_disabled;

void vertex() {
	VERTEX = VERTEX + VERTEX.y * (sin(TIME) - 1.0) * vec3(0.04, 0.04, 0.04);
}

void fragment() {
	ALBEDO = vec3(0.02, 0.042, 0.002);
}
