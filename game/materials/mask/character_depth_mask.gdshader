#undef PIXELIZE

shader_type spatial;
render_mode cull_back,unshaded,shadows_disabled,depth_test_disabled,depth_draw_never;

uniform sampler2D depth_texture : source_color, hint_depth_texture;
uniform sampler2D screen_texture : source_color, hint_screen_texture;

void fragment() {
	vec3 screen = texture(screen_texture, SCREEN_UV).xyz;
	float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	vec3 pixel_position = upos.xyz / upos.w;
	float world_z = -pixel_position.z;
	float char_z = -VERTEX.z;

	if (char_z - 2.0 > world_z) {
		// Reading screen texture instead of using alpha so the color isn't
		// multiplied by the overlapping parts of the mesh
		ALBEDO = mix(screen, vec3(0.094, 0.384, 0.655), 0.3);
	} else {
		ALPHA = .0;
	}
}
