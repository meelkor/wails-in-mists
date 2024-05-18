shader_type spatial;
render_mode unshaded,shadows_disabled,cull_disabled,fog_disabled;

//uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : source_color, hint_depth_texture;

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

	float fow_value = texture(fow_texture, world_position.xz / fow_size).x;
	float fow_weight = round(fow_value * 3.0) / 3.0;
	if (world_position.y > -100.0 && fow_weight > 0.0) {
		ALBEDO = fow_color;
		ALPHA = fow_weight;
	} else {
		discard;
	}
}
