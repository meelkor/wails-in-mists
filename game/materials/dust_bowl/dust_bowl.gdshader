shader_type spatial;
render_mode shadows_disabled;

uniform vec3 color: source_color;

const float radius = 5.0;
const float radius_sq = pow(radius, 2.0);
const float PI_HALF = PI / 2.0;


void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec3 vertex = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 std_normal = normalize(vertex - NODE_POSITION_WORLD);
	vec3 vector_to_camera = normalize(CAMERA_POSITION_WORLD - NODE_POSITION_WORLD);
	float normal_camera_angle = acos(dot(std_normal, vector_to_camera));
	ALPHA = pow((1.0 - clamp(abs(normal_camera_angle) / PI_HALF, 0.15, 1.0)), 8.0);
	ALBEDO = color;
	//ALPHA = pow(0.3 - clamp(abs(normal_camera_angle) - 0.2, 0.0, 0.3), 2.0);
	//ALPHA = abs(dot(normalize(vec4(NORMAL, 1.0) * PROJECTION_MATRIX).xyz, vector_to_center)) / PI_HALF;
}
