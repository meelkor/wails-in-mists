shader_type spatial;
render_mode unshaded,shadows_disabled,cull_disabled,fog_disabled,depth_test_disabled;

uniform sampler2D outline_mask: source_color, filter_linear_mipmap;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float blur13(sampler2D image, vec2 uv, vec2 resolution, vec2 direction) {
	float color = 0.0;
	vec2 off1 = vec2(1.411764705882353) * direction;
	vec2 off2 = vec2(3.2941176470588234) * direction;
	vec2 off3 = vec2(5.176470588235294) * direction;
	color += texture(image, uv).x * 0.1964825501511404;
	color += texture(image, uv + (off1 / resolution)).x * 0.2969069646728344;
	color += texture(image, uv - (off1 / resolution)).x * 0.2969069646728344;
	color += texture(image, uv + (off2 / resolution)).x * 0.09447039785044732;
	color += texture(image, uv - (off2 / resolution)).x * 0.09447039785044732;
	color += texture(image, uv + (off3 / resolution)).x * 0.010381362401148057;
	color += texture(image, uv - (off3 / resolution)).x * 0.010381362401148057;
	return color;
}

void fragment() {
	float val = blur13(outline_mask, SCREEN_UV, VIEWPORT_SIZE, vec2(1.2, 1.2));
	ALBEDO = vec3(0.,0.243,0.533);
	ALPHA = float(val >= 0.98) * 0.2 + float(val > 0.2 && val < 0.98) * pow(1.0 - abs(0.04 + val - 0.5), 3);
}
