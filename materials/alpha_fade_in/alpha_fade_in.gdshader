shader_type canvas_item;

uniform sampler2D bg_texture : source_color;
uniform float alpha_scissor = 1.0;

void fragment() {
	vec4 tex = texture(bg_texture, UV);
	float alpha = min(alpha_scissor, step(1. - alpha_scissor, tex.a) * tex.a) * 0.85;
	COLOR = vec4(tex.rgb, alpha);
}
