#undef PIXELIZE

shader_type spatial;
render_mode unshaded,shadows_disabled,cull_disabled,fog_disabled,depth_test_disabled,depth_draw_never;
stencil_mode read, compare_equal, 8;

uniform sampler2D depth_texture : source_color, hint_depth_texture;
uniform sampler2D screen_texture : source_color, hint_screen_texture;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float sample_min(sampler2D image, vec2 uv, vec2 resolution, vec2 direction) {
	float color = texture(image, uv).r;
	vec2 off1 = vec2(1.411764705882353) * direction;
	vec2 off2 = vec2(3.2941176470588234) * vec2(-1., 0.) * direction;
	vec2 off3 = vec2(5.176470588235294) * vec2(0., -1.) * direction;
	color = min(color, texture(image, uv + (off1 * vec2(1.0, 1.0) / resolution)).r);
	color = min(color, texture(image, uv - (off1 * vec2(-1.0, 1.0) / resolution)).r);
	color = min(color, texture(image, uv + (off2 * vec2(1.0, -1.0) / resolution)).r);
	color = min(color, texture(image, uv - (off2 * vec2(-1.0, -1.0) / resolution)).r);
	color = min(color, texture(image, uv + (off3 * vec2(-1.0, 1.0) / resolution)).r);
	color = min(color, texture(image, uv - (off3 * vec2(1.0, -1.0) / resolution)).r);
	return color;
}

void fragment() {
	float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	vec3 pixel_position = upos.xyz / upos.w;
	float world_z = -pixel_position.z;
	float char_z = -VERTEX.z;

	float depth_avg = sample_min(depth_texture, SCREEN_UV, VIEWPORT_SIZE, vec2(0.20));

	vec4 upos2 = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_avg, 1.0);
	vec3 pixel_position2 = upos2.xyz / upos2.w;
	float thing = abs(distance(pixel_position, pixel_position2));

	// Reading screen texture instead of using alpha so the color isn't
	// multiplied by the overlapping parts of the mesh
	if (thing > 0.1) {
		ALPHA = 1.0;
		ALBEDO = vec3(0., 0., 0.);
	} else {
		#ifdef PIXELIZE
			// Just an experiment to hide my ugly ass texture
			float resolution_scale = VIEWPORT_SIZE.x * 0.5;
			vec2 st = (vec2(ivec2(SCREEN_UV * resolution_scale)) + 0.5) / float(resolution_scale);
			vec4 tex_col = texture(screen_texture, st);
			ALBEDO = tex_col.rgb;
		#else
			ALPHA = 0.0;
		#endif
	}
}
