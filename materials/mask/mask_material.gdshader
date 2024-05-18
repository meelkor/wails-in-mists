shader_type spatial;
render_mode cull_back, unshaded, shadows_disabled;

void fragment() {
	vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, FRAGCOORD.z, 1.0);
	vec3 pixel_position = upos.xyz / upos.w;
	float dist = -pixel_position.z / 100.0;
	ALBEDO = vec3(dist, dist, dist);
}
