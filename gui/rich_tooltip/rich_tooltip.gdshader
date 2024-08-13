// Shader for resizable tooltip, which displays the background texture, but
// drops fragments near border to create "rotten / burnt" effect. Also adds few
// px border because why not add more condition to shaders lol
shader_type canvas_item;

const float rot_width = 8.0;
const float fade_width = 8.0;
const float border_width = 4.0;
const float opacity = 0.98;

uniform sampler2D background_tex : source_color, repeat_enable;
uniform sampler2D noise_tex : source_color, repeat_enable;

uniform vec2 size;

void fragment() {
	float noise = texture(noise_tex, UV).x;
	vec3 color = texture(background_tex, UV).xyz;
	float drop_threshold = noise * rot_width;
	ivec2 tex_size = textureSize(background_tex, 0);
	vec2 px = UV * vec2(tex_size);
	float min_dist_x = min(px.x, size.x - px.x);
	float min_dist_y = min(px.y, size.y - px.y);
	float min_dist = min(min_dist_y, min_dist_x);
	float border_dist = min_dist - drop_threshold;
	if (border_dist < 0.0) {
		discard;
	}

	color = mix(
		mix(
			color * vec3(1.0, 0.8, 0.5), // orig but brownish
			color,
			min((border_dist - fade_width) / fade_width, 1.0) // mix in the brown
		),
		vec3(.0, .0, .0),
		0.5 // darken it because I am lazy to open krita
	);

	if (min_dist < border_width) {
		// todo: create gradient with colors so we can use differnt r/g/b value
		// instead of sampling twice
		float noise2 = texture(noise_tex, UV + 0.5).x;
		color = vec3(0.2, 0.2, 0.2) * noise2;
	}

	COLOR = vec4(color, opacity);
}
