shader_type spatial;
render_mode unshaded,shadows_disabled,cull_disabled,fog_disabled;

uniform sampler2D character_mask: source_color, filter_linear;
uniform sampler2D depth_texture : source_color, hint_depth_texture;

void fragment() {
	float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	vec3 pixel_position = upos.xyz / upos.w;
	float dist = -pixel_position.z / 100.0;
	ALPHA = 0.;

	if (texture(character_mask, SCREEN_UV).x > dist + 0.01) {
			ALBEDO = vec3(0.36, 0.64, 0.98);
			ALPHA = 0.35;
	}
}
