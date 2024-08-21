shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back;
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_metallic : hint_default_white,filter_linear_mipmap,repeat_enable;
uniform vec3 albedo : source_color;
uniform float albedo_mix : hint_range(0,1);
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r,filter_linear_mipmap,repeat_enable;
uniform float specular;
uniform float metallic;

const float LIGHT_STEPS = 3.0;

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = mix(albedo_tex.rgb, albedo, albedo_mix);
	float metallic_tex = dot(texture(texture_metallic,base_uv),metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	float roughness_tex = dot(texture(texture_roughness,base_uv),roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	SPECULAR = specular;
}
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
