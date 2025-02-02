shader_type canvas_item;

instance uniform vec4 color: source_color;

void fragment() {
	COLOR = color * COLOR.a;
}
