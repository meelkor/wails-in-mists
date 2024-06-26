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
	bool discard_fragment = true;

	float offset = pow(abs(fract(TIME / period) * 2.0 - 1.0), 1.5) * max_offset;
	vec3 vertex = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec4 albedo_tex;
	vec3 target;
 	vec3 uv;
	float alpha = 1.0;

	float goal_count = float(textureSize(goal_positions, 0).x);
	for (float i = 1.0; i < goal_count; i++) {
		target = texture(goal_positions, vec2(i / goal_count, 0.0)).xyz;
		uv = vertex - target;
		uv = (uv + 0.7 / 2.0) / 0.7;
		uv = clamp(uv + (round(uv) * 2.0 - 1.0) * offset, 0.0, 1.0);
		albedo_tex = texture(texture_albedo, uv.xz);
		alpha = albedo_tex.a;
		discard_fragment = false;
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
		alpha = round(fract(final_total_distance * DASHES_PAR_M - TIME * DASHED_ANIMATION_SPEED));
		discard_fragment = false;
		ALBEDO = mix(ALBEDO, vec3(.09, .09, .09), step(color_length, final_total_distance));
	}

	if (discard_fragment || alpha < 0.2) {
		discard;
	}
}
