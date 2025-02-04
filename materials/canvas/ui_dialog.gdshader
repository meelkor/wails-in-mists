// Basically my version of the NinePatchRect, cause why should I use some
// existing, better performing and more stable node, when I can implement this
// frankenstein myself. Currently texture parameters are hard-coded.
//
// - Allows adding extra tint color to the background
// - Allows making borders grayscale

shader_type canvas_item;
render_mode blend_mix;

uniform vec2 size;
uniform vec4 border_tint = vec4(0.0, 0.0, 0.0, 0.0);
uniform float bg_opacity: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float grayscale: hint_range(0.0, 1.0, 0.1) = 0.8;
uniform sampler2D bg_texture : repeat_enable, source_color;

const float border_squash = 1.0;
const float border_size = 6.0;
const float bg_size = 512.0;

const float tex_size = border_size + bg_size;
const float bg_range = bg_size / tex_size;
const float border_range = border_size / tex_size;

void fragment() {
	vec2 px_pos = UV * size;

	// UV if displaying background
	vec2 bg_uv = fract(px_pos / tex_size / bg_range) * bg_range;

	// Which part of the border should be visible or zero, if it shouldn't be visible
	vec2 topleft_border = abs(min(vec2(0.0, 0.0), px_pos - border_size)) / border_size;
	vec2 bottomright_border = max(vec2(0.0, 0.0), px_pos + border_size - size) / border_size;

	// For each value either 0 - no, 1 - yes
	vec2 is_topleft = ceil(topleft_border);
	vec2 is_bottomright = ceil(bottomright_border);
	float is_border = min(1.0, is_bottomright.x + is_bottomright.y + is_topleft.x + is_topleft.y);
	float is_bg = abs(is_border - 1.0);

	// UVs for each border case
	vec2 left_uv = vec2(bg_range + (1.0 - topleft_border.x) * border_range, bg_uv.y);
	vec2 top_uv = vec2(bg_uv.x, bg_range + topleft_border.y * border_range);
	vec2 right_uv = vec2(bg_range + bottomright_border.x * border_range, bg_uv.y);
	vec2 bottom_uv = vec2(bg_uv.x, bg_range + bottomright_border.y * border_range);

	// Get the real UV
	vec2 uv = is_bg * bg_uv
		+ max(0.0, is_topleft.y - is_topleft.x - is_bottomright.x) * top_uv
		+ is_topleft.x * left_uv
		+ is_bottomright.x * right_uv
		+ max(0.0, is_bottomright.y - is_topleft.x - is_bottomright.x) * bottom_uv;

	COLOR *= texture(bg_texture, uv);

	// Apply color effects
	if (is_bg > 0.0) {
		COLOR.a *= bg_opacity;
	} else if (border_tint.w > 0.0) {
		// For some weird reason without the condition alpha ends up 0 when border_tint.alpha is zero??
		COLOR = mix(COLOR, COLOR / (1.0 - vec4(border_tint.xyz, 1.0)), border_tint.w);
	}
	COLOR.g = mix(COLOR.g, COLOR.r, grayscale * is_border);
	COLOR.b = mix(COLOR.b, COLOR.r, grayscale * is_border);
}
