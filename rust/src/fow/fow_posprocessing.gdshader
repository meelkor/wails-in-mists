shader_type spatial;
render_mode unshaded,shadows_disabled,cull_disabled,fog_disabled;

uniform sampler2D depth_texture : source_color, hint_depth_texture;
// World positions of all controlled characters
uniform sampler2D positions_texture: filter_nearest;

uniform sampler2D fow_texture;
uniform vec3 fow_color : source_color;
uniform vec2 fow_size;

varying mat4 CAMERA;

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
	CAMERA = INV_VIEW_MATRIX;
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	vec4 world = CAMERA * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;

	int character_count = textureSize(positions_texture, 0).x;
	vec3 character_pos;
	float mul = 1.0;
	for (int i = 0; i < character_count; i++) {
		character_pos = texture(positions_texture, vec2((float(i) + 0.5) / float(character_count), 0.5)).xyz;
		mul = min(pow(distance(character_pos, world_position) / 7.0, 1.5), mul);
	}
	mul = min(1.0, mul);

	float fow_value = texture(fow_texture, world_position.xz / fow_size).x;
	if (world_position.y > -100.0 && fow_value > 0.0) {
		ALBEDO = fow_color;
		ALPHA = fow_value * mul;
	} else {
		discard;
	}
}
