// Shader which renders stylized solid color border with optional texture
// inside.
//
// An unoptimized shader and can be prolly merged with other shader / godot
// provided functionality later. I should prolly upload built textures so there
// is only one sampling rather than 3 lol
shader_type canvas_item;

uniform vec2 size = vec2(1.0, 1.0);
uniform float noise_offset;
uniform float bright = 1.0;
uniform float border_width = 1.0;
uniform float hover_weight = 0.0;
uniform bool has_icon = false;

uniform sampler2D noise_tex : source_color, repeat_enable;
uniform sampler2D icon_tex : source_color;
uniform sampler2D item_bg_tex : source_color;

void fragment() {
	vec2 px = size * UV;
	float noise_val = texture(noise_tex, UV + noise_offset).x;
	vec4 bg = texture(item_bg_tex, UV);
	if (
		px.x <= border_width || px.x > size.x - border_width
		|| px.y <= border_width || px.y > size.y - border_width
	) {
		// Borders
		float bg_brightness = 0.1 + 0.26 * (1.0 - noise_val);
		COLOR = vec4(bg_brightness, bg_brightness, bg_brightness, 1.0);
	} else {
		// Content
		vec4 bg_color = vec4(0.02 + 0.10 * noise_val, 0.06, 0.06, 0.7);
		if (has_icon) {
			// icon + bg combined + tint for color rarity???
			vec4 icon = texture(icon_tex, UV);
			vec4 rarity_tint = vec4(0.4, 1.0, 0.2, 1.0);
			COLOR = mix(bg * rarity_tint, icon, icon.a);
		} else {
			// Default semi-transparent bg
			COLOR = vec4(0.02 + 0.10 * noise_val, 0.06, 0.06, 0.7);
		}
	}

	// Hover highlight
	COLOR = mix(COLOR, vec4(1.0, 1.0, 1.0, 1.0), hover_weight * 0.055);
}
