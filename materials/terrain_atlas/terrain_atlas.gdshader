shader_type spatial;

uniform sampler2D texture_atlas: filter_nearest_mipmap,repeat_enable,source_color;
uniform sampler2D texture_map: filter_linear,repeat_disable;

const float STEP_INT = 16.0;
const float STEP = STEP_INT / 256.0;
const float N_OF_TEXTURES = 2.0;

void fragment() {
	vec2 offset = fract(UV) / vec2(N_OF_TEXTURES, 1.0);
	vec4 mapv = texture(texture_map, UV2);
	vec2 tex_offset = floor(mapv.xy / STEP) / N_OF_TEXTURES;
	vec4 tex_a = texture(texture_atlas, offset + vec2(tex_offset.x, 0.0));
	vec4 tex_b = texture(texture_atlas, offset + vec2(tex_offset.y, 0.0));

	ALBEDO = mix(tex_a, tex_b, mapv.z).xyz;
}
