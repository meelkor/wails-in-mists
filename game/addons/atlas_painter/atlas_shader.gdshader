shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_toon,specular_toon;

// Not using mipmaps due to UV discontinuity I can't be bothered to fix.
// Hopefully they are not really needed in topdown game.
uniform sampler2D texture_atlas: filter_nearest,repeat_disable,source_color;
uniform sampler2D texture_map: filter_linear,repeat_disable;
uniform sampler2D texture_normal_atlas: filter_nearest,repeat_enable,hint_normal;
uniform float texture_count;

// Editor only, currently "hovered" spot on the UV map, around which should the
// brush shape be drawn.
uniform vec2 brush_uv;
// Editor only, brush size in "UV units"
uniform float brush_size = 0.0;

const float STEP = 1.0 / 255.0;
const float LIGHT_STEPS = 4.0;

void fragment() {
	vec2 offset = fract(UV) / vec2(texture_count, 1.0);
	vec4 mapv = texture(texture_map, UV2);
	vec2 tex_offset = mapv.xy * 255.0 / texture_count;
	vec2 uv_a = offset + vec2(tex_offset.x, 0.0);
	vec2 uv_b = offset + vec2(tex_offset.y, 0.0);
	vec3 tex_a = texture(texture_atlas, uv_a).xyz;
	vec3 tex_b = texture(texture_atlas, uv_b).xyz;
	vec3 normal_a = texture(texture_normal_atlas, uv_a).xyz;
	vec3 normal_b = texture(texture_normal_atlas, uv_b).xyz;

	NORMAL_MAP = mix(normal_a, normal_b, mapv.z);
	NORMAL_MAP_DEPTH = 0.3;
	ALBEDO = mix(tex_a, tex_b, mapv.z);

	// TODO: do not run in game
	if (brush_size > 0.0) {
		float brush_dist = distance(UV2, brush_uv);
		// TODO: try to somehow calculate how much is approx one pixel on the
		// mesh
		if (brush_dist > brush_size && brush_dist < brush_size + 1.0 / 512.0 * 0.25) {
			ALBEDO = vec3(1.0, 0.0, 0.0);
		}
	}
}

void light() {
	float dotnl = dot(NORMAL, LIGHT);
	float sample_position = clamp(dotnl, 0.01, 1.0);
	vec3 ramp_light = vec3(round(sample_position * LIGHT_STEPS) / LIGHT_STEPS);
	vec3 diffuse_light = ramp_light.rgb * clamp(LIGHT_COLOR * min(1.0, ATTENUATION), vec3(0,0,0), vec3(1,1,1));
	DIFFUSE_LIGHT = max(diffuse_light * diffuse_light * diffuse_light * diffuse_light, DIFFUSE_LIGHT);
}
