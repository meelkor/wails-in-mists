shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back;

const float LIGHT_STEPS = 3.0;

#include "./character_fragment.gdshaderinc"

void light() {
	float dotnl = dot(NORMAL, LIGHT);
	// float dotnl = dot(vec3(pow(NORMAL.x, 2.0), pow(NORMAL.y, 2.0), pow(NORMAL.z, 2.0)), LIGHT);
	// I changed original 1.0 to 1.5 because it looks better, but dunno what it
	// does lmao
	float sample_position = clamp(dotnl, 0.01, 1.0);
	vec3 ramp_light = vec3(round(sample_position * LIGHT_STEPS) / LIGHT_STEPS);
	vec3 diffuse_light = ramp_light.rgb * clamp(LIGHT_COLOR * min(1.0, ATTENUATION + 0.1), vec3(0,0,0), vec3(1,1,1));
	// DIFFUSE_LIGHT = diffuse_light;
	DIFFUSE_LIGHT = max(diffuse_light, DIFFUSE_LIGHT);
	// DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR;
	// DIFFUSE_LIGHT = vec3(1.0) * dot(NORMAL, LIGHT);
	// DIFFUSE_LIGHT = round(clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR * LIGHT_STEPS) / LIGHT_STEPS;
}
