shader_type spatial;
render_mode unshaded,shadows_disabled,fog_disabled;

uniform vec4 wire_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float wire_width: hint_range(0.0, 40.0) = 2.0;
uniform float wire_smoothness: hint_range(0.0, 0.1) = 0.01;
uniform sampler2D background: source_color;

varying vec3 barys;

void vertex() {
	int index = VERTEX_ID % 3;
	switch (index) {
		case 0:
			barys = vec3(1.0, 0.0, 0.0);
			break;
		case 1:
			barys = vec3(0.0, 1.0, 0.0);
			break;
		case 2:
			barys = vec3(0.0, 0.0, 1.0);
			break;
	}
}

void fragment() {
	vec3 deltas = fwidth(barys);
	vec3 barys_s = smoothstep(deltas * wire_width - wire_smoothness, deltas * wire_width + wire_smoothness, barys);
	float wires = min(barys_s.x, min(barys_s.y, barys_s.z));
	vec3 tex_color = texture(background, UV).rgb;
	float avg = (tex_color.r + tex_color.g + tex_color.b) / 3.0;
	// todo: change texture and remove avg & power
	vec3 color = vec3(abs(pow(avg * 20., 2)) / 2.);
	ALBEDO = mix(color, wire_color.rgb, (1.0 - wires) * wire_color.a);
}
