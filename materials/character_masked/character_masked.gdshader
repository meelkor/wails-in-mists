shader_type spatial;
render_mode cull_back,unshaded,shadows_disabled;

uniform sampler2D character_mask: source_color, filter_linear;

void fragment() {
	if (texture(character_mask, SCREEN_UV).x > 0.02) {
		ALBEDO = vec3(0.36, 0.64, 0.98);
		ALPHA = 0.35;
	} else {
		discard;
	}
}
