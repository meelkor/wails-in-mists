shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D albedo_tex: source_color;
uniform float alpha_scissor: hint_range(0.0, 1.0, 0.001);
uniform float burn_range: hint_range(0.0, 1., 0.001);
uniform vec3 burn_color: source_color;

void fragment() {
	vec4 cl = texture(albedo_tex, UV);

	if (cl.a < alpha_scissor + burn_range && cl.a > alpha_scissor) {
		ALBEDO = burn_color;
		ALPHA = 1.;
		//ALPHA = (cl.a - alpha_scissor) / (alpha_scissor + 0.05) * (1. - alpha_scissor);
	} else {
		discard;
	}
}
