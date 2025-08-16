shader_type canvas_item;

const float ICON_W = 1. / 7.;
const float CIRCLE = 2. * PI;

uniform float saturation = 1.0;
uniform float offset = 0.0;
uniform float used_ratio = 0.0;

void fragment() {
	vec2 neutral_uv = vec2(UV.x * ICON_W, UV.y);
	vec2 uv = vec2(UV.x * ICON_W + offset * ICON_W, UV.y);
	vec4 neutral = texture(TEXTURE, neutral_uv);
	vec2 auv = vec2(UV.x - 0.5, UV.y - 0.5);
	float angle = atan(auv.y, auv.x) / CIRCLE + 0.25;
	if (angle < 0.0) {
		angle = 1. - abs(angle);
	}
	COLOR = mix(neutral, texture(TEXTURE, uv), float(used_ratio < angle));
	if (COLOR.w < 0.19) {
		discard;
	} else {
		COLOR.a = 1.0;
	}
}
