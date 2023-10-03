shader_type spatial;

uniform vec3 circle_color;

void fragment() {
	const float radius = 0.45;
	const float thickness = 0.04;
	float dist = sqrt(pow(0.5 - UV.x, 2) + pow(0.5 - UV.y, 2));
	if (dist > radius && dist < radius + thickness) {
		ALBEDO = circle_color;
	} else {
		discard;
	}
}
