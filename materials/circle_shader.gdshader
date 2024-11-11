// I hate shaders with good performance or using tools created for this purpose
// such as decals <3
shader_type spatial;
render_mode cull_back,unshaded,shadows_disabled;

instance uniform vec3 circle_color;
instance uniform float spacing = 1.0;

void fragment() {
	const float radius = 0.45;
	const float thickness = 0.04;
	float dist = sqrt(pow(0.5 - UV.x, 2) + pow(0.5 - UV.y, 2));
	float angle = 2.0 * acos(abs(UV.x - .5) / dist) / PI; // 0 - 1 per quadrant
	float quadrant_check = abs(floor(UV.x * 2.0) - floor(UV.y * 2.0));
	angle = abs(quadrant_check - angle); // fix orientation per quadrant
	angle += (floor(UV.x * 2.0) + floor(UV.y * 2.0)); // make angle continuous
	angle *= 2.5; // spacing
	if (dist > radius && dist < radius + thickness && fract(angle + TIME) < spacing) {
		ALBEDO = circle_color;
	} else {
		discard;
	}
}
