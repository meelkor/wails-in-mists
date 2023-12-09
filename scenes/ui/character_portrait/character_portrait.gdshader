shader_type canvas_item;

uniform float overlay_opacity;

void fragment() {
	COLOR = mix(texture(TEXTURE, UV), vec4(0.12, 0.12, 0.12, 1.0), overlay_opacity);
}
