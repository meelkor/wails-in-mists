shader_type spatial;
render_mode cull_back,unshaded,shadows_disabled;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_linear;
uniform float period : hint_range(0.0, 3, 0.01);
uniform float max_offset : hint_range(0.0, 0.5, 0.01);

uniform vec3 goal_positions[4];

void fragment() {
	bool drawn = false;

	float offset = pow(abs(fract(TIME / period) * 2.0 - 1.0), 1.5) * max_offset;
	vec3 vertex = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec4 albedo_tex;
	vec3 target;
 	vec3 uv;

	for (int i = 0; i < 4; i++) {
		target = goal_positions[i];
		uv = vertex - target;
		if (length(uv) < 0.6) {
			uv = (uv + 0.5) * 1.3;
			uv = clamp(uv + (round(uv) * 2.0 - 1.0) * offset, 0.0, 1.0);
			albedo_tex = texture(texture_albedo, uv.xz);
			ALBEDO = albedo.rgb;
			ALPHA = albedo_tex.a;
			drawn = true;
		}
	}

	if (!drawn) {
		discard;
	}
}
