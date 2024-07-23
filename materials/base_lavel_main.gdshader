shader_type spatial;
render_mode unshaded,shadows_disabled,cull_disabled,fog_disabled;

varying mat4 CAMERA;

uniform sampler2D screen_texture: source_color, filter_linear, hint_screen_texture;
uniform sampler2D character_mask: source_color, filter_linear;
uniform sampler2D outline_mask: source_color, filter_linear;
uniform sampler2D depth_texture : source_color, hint_depth_texture;

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
	CAMERA = INV_VIEW_MATRIX;
}

void fragment() {
	float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	vec3 pixel_position = upos.xyz / upos.w;
	float dist = -pixel_position.z / 100.0;

	vec4 outline_tex = textureGather(outline_mask, SCREEN_UV);
	float val = (outline_tex.x + outline_tex.y + outline_tex.z + outline_tex.w) / 4.0;
	if (val > 0.02 && val < 0.98) {
		ALBEDO = vec3(0.36, 0.64, 0.98);
		ALPHA = 0.8;
	} else if (texture(character_mask, SCREEN_UV).x > dist + 0.01) {
		ALBEDO = vec3(0.36, 0.64, 0.98);
		ALPHA = 0.35;
	} else {
		discard;
	}
}
