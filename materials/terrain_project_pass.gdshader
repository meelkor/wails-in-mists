// Absolutely unhinged shader which projects some animated "decals" (movement
// goal circles and combat movement paths) on the terrain. This is probably way
// less performant than adding extra geometry which we'd shape according to the
// terrain but I had too much fun creating this mess <3

shader_type spatial;
render_mode cull_back,unshaded,shadows_disabled;

// Number line vertices. Needs to match the constant used when preparing the
// uniform data.
const uint LINE_VERTEX_COUNT = 6u;
// Basically LINE_VERTEX_COUNT_MINUS - 1
const uint LINE_VERTEX_COUNT_MINUS = 5u;

const float LINE_RADIUS = 0.02;

const float DASHES_PAR_M = 4.0;

const float DASHED_ANIMATION_SPEED = 0.75;

// Color for both the goal circles and movement path
uniform vec4 albedo : source_color;
// The texture of the goal circle itself
uniform sampler2D texture_albedo : source_color,filter_linear;
// Goal circle animation duration
uniform float period : hint_range(0.0, 3, 0.01) = 1.25;
// Offset used to correctly "deform" the input texture to create in-out
// animation
uniform float max_offset : hint_range(0.0, 0.5, 0.01) = 0.05;
// Center positions for the "goal circles"
uniform sampler2D goal_positions: filter_nearest;
// Vertices for the projected line. If the path has less components than
// LINE_VERTEX_COUNT, just repeat the last vertex for the rest of the
// components.
uniform vec2 line_vertices[LINE_VERTEX_COUNT];
// Length of the projected dashed line that will be in color
uniform float color_length = 0;
// Number of meters already moved - provided so the animation time gets offset
// as character moves
uniform float moved = 0;
// Center positions for selection circles in 1D texture, first pixel is always
// empty. W component contains radius.
uniform sampler2D circle_positions: filter_nearest;
// Colors for selection circles in 1D texture, must be same size as
// circle_positions.
uniform sampler2D circle_colors: filter_nearest;
// Extra configuration for selection circles in 1D texture, must be same size as
// circle_positions. vec4(dashed_ratio, fade, _, _)
uniform sampler2D circle_extras: filter_nearest;
uniform float circle_count;

// Stolen from https://www.shadertoy.com/view/fstSW8
vec2 find_nearest_point_on_line(vec2 origin, vec2 end, vec2 point) {
    //Get heading
    vec2 heading = (end - origin);
    float magnitudeMax = length(heading);
    heading = normalize(heading);

    // Do projection from the point but clamp it
    vec2 lhs = point - origin;
    float dotP = dot(lhs, heading);
    dotP = clamp(dotP, 0.0f, magnitudeMax);
    return origin + heading * dotP;
}

void fragment() {
	ALBEDO = albedo.xyz;
	ALPHA = 0.0;
	bool discard_fragment = true;

	float offset = pow(abs(fract(TIME / period) * 2.0 - 1.0), 1.5) * max_offset;
	vec3 vertex = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec4 albedo_tex;
	vec3 target;
 	vec3 uv;
	float alpha = 0.0;

	int goal_count = textureSize(goal_positions, 0).x - 1;
	for (int i = 0; i < goal_count + 1; i++) {
		target = texture(goal_positions, vec2((float(i + 1) + 0.5) / float(goal_count + 1), 0.5)).xyz;
		// todo: it should be possible without condition here somehow
		if (distance(vertex, target) < 0.5) {
			uv = vertex - target;
			uv = (uv + 0.7 / 2.0) / 0.7;
			uv = clamp(uv + (round(uv) * 2.0 - 1.0) * offset, 0.0, 1.0);
			albedo_tex = texture(texture_albedo, uv.xz);
			ALPHA = alpha = albedo_tex.a;
			discard_fragment = ALPHA < 0.2;
		}
	}

	// Project animated dashed line according to the line vertices. If this is
	// moved into the terrain shader, no condition would be nedded.
	vec2 line_src;
	vec2 line_end;
	// Cumulated distances between the path vectors. First value is always 0
	float total_distances[LINE_VERTEX_COUNT];
	total_distances[0] = 0.0;
	// The closest distance to the line we've found so far. If the final lowest
	// value is below LINE_RADIUS, fragment is drawn.
	float distance_to_line = 1000.0;
	// Nearest point for each line
	vec2 nearest_points_on_line[LINE_VERTEX_COUNT_MINUS];
	// Index of the line nearest to the fragment
	uint nearest_line_index = 255u;
	// Index of the line nearest to the fragment
	float current_distance;
	// Current sum of distances
	float distance_until_then = 0.0;
	// Used to calculate the closest index
	uint index_or_hausnumero;

	for (uint i = 0u; i < LINE_VERTEX_COUNT_MINUS; i++) {
		line_src = line_vertices[i];
		line_end = line_vertices[i + 1u];
		nearest_points_on_line[i] = find_nearest_point_on_line(line_src, line_end, vertex.xz);
		current_distance = distance(nearest_points_on_line[i], vertex.xz);
		distance_to_line = min(distance_to_line, current_distance);
		total_distances[i + 1u] = total_distances[i] + distance(line_src, line_end);
		// Result of this line is either current index if the fragment belongs
		// to this line or integer much higher than our indices. This way we
		// can store the index without any conditions.
		index_or_hausnumero = i + uint(100.0 * max(max(current_distance, LINE_RADIUS) - LINE_RADIUS * 1.5, 0.0));
		nearest_line_index = min(nearest_line_index, index_or_hausnumero);
	}

	if (distance_to_line < LINE_RADIUS) {
		// Final distance from the start of the whole path (= sum of all
		// previous path segments + distance to the fragment)
		float final_total_distance = total_distances[nearest_line_index] + distance(line_vertices[nearest_line_index], nearest_points_on_line[nearest_line_index]);
		// Apply dashed pattern
		alpha = round(fract((moved + final_total_distance) * DASHES_PAR_M - TIME * DASHED_ANIMATION_SPEED));
		discard_fragment = false;
		ALBEDO = mix(ALBEDO, vec3(.09, .09, .09), step(color_length, final_total_distance));
	}

	// Draw circles (possible animated) on positions provided by
	// circle_positions texture
	//
	// Fuck performance, to hell with decals
	for (float i = 1.5; i < circle_count; i += 1.0) {
		const float half_width = 0.015;
		vec2 circle_uv = vec2(i / circle_count, 0.5);
		vec4 pos = texture(circle_positions, circle_uv);
		float pos_dist = distance(pos.xyz, vertex);
		// todo: pass character's size via texture (w component of position?)
		float line_dist = pos_dist - pos.w;
		float abs_line_dist = abs(line_dist);
		vec4 extras = texture(circle_extras, circle_uv);
		if (abs_line_dist < half_width) {
			const float radius = 0.45;
			const float thickness = 0.04;
			const float spacing = 0.5;
			float dist_2d = distance(vertex.xz, pos.xz);
			float angle = 2.0 * acos(abs(vertex.x - pos.x) / dist_2d) / PI; // 0 - 1 per quadrant
			float x_quadrant = (sign(vertex.x - pos.x) + 1.0) / 2.0;
			float z_quadrant = (sign(vertex.z - pos.z) + 1.0) / 2.0;
			float quadrant_check = abs(x_quadrant - z_quadrant);
			angle = abs(quadrant_check - angle); // fix orientation per quadrant
			angle += x_quadrant + z_quadrant; // make angle continuous
			angle *= 2.5; // dash size

			if (fract(angle + TIME) < extras.x) {
				vec4 cl = texture(circle_colors, circle_uv);
				discard_fragment = false;
				// there's got to be better way to antialias
				alpha = ALPHA = sqrt(1.0 - abs_line_dist / half_width) * cl.w;
				ALBEDO = cl.xyz;
			}
		} else if (line_dist < 0.0 && extras.y >= 0.0) {
			if (discard_fragment) {
				ALBEDO = vec3(0.4, 0.07, 0.0);
			}
			ALPHA = max(mix(1.0, pow(pos_dist / pos.w, 4), extras.y) * 0.05, ALPHA);
			alpha = 1.0;
			discard_fragment = false;
		}
	}

	if (discard_fragment || alpha < 0.2) {
		discard;
	}
}
