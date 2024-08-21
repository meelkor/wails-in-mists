shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back;

uniform sampler2D texture_atlas: filter_nearest_mipmap,repeat_enable,source_color;
uniform sampler2D texture_map: filter_nearest_mipmap,repeat_disable;
uniform sampler2D texture_atlas_normal: filter_nearest_mipmap,repeat_disable,hint_normal;
uniform float texture_count;

const float STEP_INT = 16.0;
const float STEP = STEP_INT / 256.0;
const float LIGHT_STEPS = 4.0;

void fragment() {
	vec2 offset = fract(UV) / vec2(texture_count, 1.0);
	vec4 mapv = texture(texture_map, UV2);
	vec2 tex_offset = floor(mapv.xy / STEP) / texture_count;
	vec2 uv_a = offset + vec2(tex_offset.x, 0.0);
	vec2 uv_b = offset + vec2(tex_offset.y, 0.0);
	vec3 tex_b = texture(texture_atlas, uv_b).xyz;
	vec3 tex_a = texture(texture_atlas, uv_a).xyz;
	vec3 normal_a = texture(texture_atlas_normal, offset + vec2(tex_offset.x, 0.0)).xyz;
	vec3 normal_b = texture(texture_atlas_normal, offset + vec2(tex_offset.y, 0.0)).xyz;

	NORMAL_MAP = mix(normal_a, normal_b, mapv.z);
	NORMAL_MAP_DEPTH = 0.5;
	ALBEDO = mix(tex_a, tex_b, mapv.z);
}

void light() {
	float dotnl = dot(NORMAL, LIGHT);
	float sample_position = clamp(dotnl, 0.01, 1.0);
	vec3 ramp_light = vec3(round(sample_position * LIGHT_STEPS) / LIGHT_STEPS);
	vec3 diffuse_light = ramp_light.rgb * clamp(LIGHT_COLOR * min(1.0, ATTENUATION), vec3(0,0,0), vec3(1,1,1));
	DIFFUSE_LIGHT = max(diffuse_light * diffuse_light * diffuse_light * diffuse_light, DIFFUSE_LIGHT);
}
