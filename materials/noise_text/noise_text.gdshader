shader_type canvas_item;

uniform sampler2D noise_tex: source_color;

// Just fucking around, todo: make a container instead
void fragment() {
	vec4 noise = texture(
		noise_tex,
		fract(UV + vec2(0., TIME * 0.02))
	);
	float enabled = float(max(max(max(COLOR.r, COLOR.g), COLOR.b), COLOR.a) < 0.9);
	if (enabled * noise.x > 0.25 + (0.15 * abs(sin(TIME * 0.35)))) {
		discard;
	}
	COLOR = mix(COLOR, COLOR * 0.6, enabled);
}
