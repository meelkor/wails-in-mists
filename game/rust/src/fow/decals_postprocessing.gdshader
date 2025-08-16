shader_type spatial;
render_mode unshaded,shadows_disabled,cull_disabled,fog_disabled,depth_test_disabled,depth_draw_never;
stencil_mode read, compare_equal, 4;

uniform sampler2D depth_texture: source_color, hint_depth_texture;

// Circle decal projection

// Center positions for circles in 1D texture, first pixel is always empty. W
// component contains radius.
uniform sampler2D circle_positions: filter_nearest;
// Colors for circles in 1D texture, must be same size as circle_positions.
uniform sampler2D circle_colors: filter_nearest;
// Extra configuration for circles in 1D texture, must be same size as
// circle_positions. vec4(dashed_ratio, fade, _, _)
uniform sampler2D circle_extras: filter_nearest;
uniform float circle_count;

// Line decal projection

// Color of navigation line which character no longer can walk
const vec3 LINE_DEFAULT_COLOR = vec3(.09, .09, .09);
// Color of navigation line which character can walk
const vec3 LINE_WALKABLE_COLOR = vec3(0.094, 0.384, 0.655) - LINE_DEFAULT_COLOR;
// Color of navigation line in which they enter enemy reach for AoO
const vec3 LINE_DANGER_COLOR = vec3(0.755, 0.054, 0.154) - LINE_DEFAULT_COLOR;
const float LINE_RADIUS = 0.02;
const float DASHES_PAR_M = 4.0;
const float DASHED_ANIMATION_SPEED = 0.5;
uniform vec2 line_vertices[10];
uniform uint line_size = 0u;
// Length of the projected dashed line that will be in color
uniform float color_length = 0;
uniform vec2 line_red_segment = vec2(0., 0.);
// Number of meters already moved - provided so the animation time gets offset
// as character moves
uniform float moved = 0;

varying mat4 CAMERA;

// Stolen from https://www.shadertoy.com/view/fstSW8
vec2 find_nearest_point_on_line(vec2 origin, vec2 end, vec2 point) {
    // Get heading
    vec2 heading = (end - origin);
    float magnitudeMax = length(heading);
    heading = normalize(heading);

    // Do projection from the point but clamp it
    vec2 lhs = point - origin;
    float dotP = dot(lhs, heading);
    dotP = clamp(dotP, 0.0f, magnitudeMax);
    return origin + heading * dotP;
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
	CAMERA = INV_VIEW_MATRIX;
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	vec4 world = CAMERA * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 vertex = world.xyz / world.w;

	ALPHA = 0.;

	// Draw circles on positions provided by circle_positions texture
	//
	// Fuck performance, to hell with decals
	for (float i = 1.5; i < circle_count; i += 1.0) {
		const float half_width = 0.015;
		vec2 circle_uv = vec2(i / circle_count, 0.5);
		vec4 pos = texture(circle_positions, circle_uv);
		float pos_dist = distance(pos.xyz, vertex);
		if (pos_dist < pos.w + half_width) {
			float line_dist = pos_dist - pos.w;
			float abs_line_dist = abs(line_dist);
			vec4 extras = texture(circle_extras, circle_uv);
			float circle_border_a = float(abs_line_dist < half_width);
			float inside_a = mix(0., pow(pos_dist / pos.w, 2), extras.y) * 0.05;
			vec4 cl = texture(circle_colors, circle_uv);
			// Calculate clockwise angle for dashed
			vec2 ptn = pos.xz - vertex.xz;
			float angle = atan(ptn.y / ptn.x) / PI * extras.x;
			float dashed_a = float(fract(angle + TIME) * float(bool(extras.x)) < 0.5);
			ALBEDO = cl.xyz;
			ALPHA = max(circle_border_a, inside_a) * dashed_a * cl.a;
		}
	}

	// Project dashed line defined by line_vertices texture.
	//
	// todo: It was fun to write, but introduce some node which creates the
	// line out of decals (making meshes copy terrain would be difficult due to
	// Terrain3D)
	float total_distance = 0.;
	float min_distance = 1000.;
	float prev_sum = 0.;
	for (uint i = 1u; i < line_size; i++) {
		vec2 segment_start = line_vertices[i - 1u];
		vec2 segment_end = line_vertices[i];
		vec2 nearest_points_on_line = find_nearest_point_on_line(segment_start, segment_end, vertex.xz);
		float line_len = distance(segment_start, segment_end);
		float on_line_dist = distance(segment_start, nearest_points_on_line);
		float current_distance = distance(nearest_points_on_line, vertex.xz);
		float comp = step(current_distance, min_distance);
		total_distance *= (1. - comp);
		total_distance += (prev_sum + on_line_dist) * comp;
		min_distance = min(min_distance, current_distance);
		prev_sum += line_len;
	}

	if (min_distance < LINE_RADIUS) {
		float line_alpha = round(fract((moved + total_distance) * DASHES_PAR_M - TIME * DASHED_ANIMATION_SPEED));
		float red_weight = float(line_red_segment.x < total_distance && line_red_segment.y > total_distance);
		float blue_weight = float(total_distance < color_length && !bool(red_weight));
		// todo: consider using texture for the color transitions
		vec3 line_color = LINE_DEFAULT_COLOR + (
			+ blue_weight * LINE_WALKABLE_COLOR
			+ red_weight * LINE_DANGER_COLOR
		);
		ALBEDO = line_color;
		ALPHA = line_alpha;
	}
}
