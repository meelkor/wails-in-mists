shader_type spatial;

uniform sampler2D texture_atlas: filter_nearest_mipmap,repeat_enable,source_color;
uniform sampler2D texture_map: filter_linear,repeat_disable;
uniform sampler2D texture_atlas_normal: filter_linear,repeat_disable,hint_normal;

const float STEP_INT = 16.0;
const float STEP = STEP_INT / 256.0;
const float N_OF_TEXTURES = 2.0;

void fragment() {
	vec2 offset = fract(UV) / vec2(N_OF_TEXTURES, 1.0);
	vec4 mapv = texture(texture_map, UV2);
	vec2 tex_offset = floor(mapv.xy / STEP) / N_OF_TEXTURES;
	vec2 uv_a = offset + vec2(tex_offset.x, 0.0);
	vec2 uv_b = offset + vec2(tex_offset.y, 0.0);
	vec3 tex_b = texture(texture_atlas, uv_b).xyz;
	vec3 tex_a = texture(texture_atlas, uv_a).xyz;
	vec3 normal_a = texture(texture_atlas_normal, offset + vec2(tex_offset.x, 0.0)).xyz;
	vec3 normal_b = texture(texture_atlas_normal, offset + vec2(tex_offset.y, 0.0)).xyz;

	NORMAL_MAP = mix(normal_a, normal_b, mapv.z) * vec3(1.0, 1.0, -1.0);
	NORMAL_MAP_DEPTH = 2.0;
	ALBEDO = mix(tex_a, tex_b, mapv.z);
}
