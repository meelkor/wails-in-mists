shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_lambert,specular_schlick_ggx,skip_vertex_transform;

/* This shader is generated based upon the debug views you have selected.
 * The terrain function depends on this shader. So don't change:
 * - vertex positioning in vertex()
 * - terrain normal calculation in fragment()
 * - the last function being fragment() as the editor injects code before the closing }
 *
 * Most will only want to customize the material calculation and PBR application in fragment()
 *
 * Uniforms that begin with _ are private and will not display in the inspector. However,
 * you can set them via code. You are welcome to create more of your own hidden uniforms.
 *
 * This system only supports albedo, height, normal, roughness. Most textures don't need the other
 * PBR channels. Height can be used as an approximation for AO. For the rare textures do need
 * additional channels, you can add maps for that one texture. e.g. an emissive map for lava.
 *
 */

// Private uniforms

uniform float _region_size = 1024.0;
uniform float _region_texel_size = 0.0009765625; // = 1/1024
uniform float _vertex_spacing = 1.0;
uniform float _vertex_density = 1.0; // = 1/_vertex_spacing
uniform int _region_map_size = 32;
uniform int _region_map[1024];
uniform vec2 _region_locations[1024];
uniform highp sampler2DArray _height_maps : repeat_disable;
uniform highp usampler2DArray _control_maps : repeat_disable;
uniform highp sampler2DArray _color_maps : source_color, filter_nearest_mipmap_anisotropic, repeat_disable;
uniform highp sampler2DArray _texture_array_albedo : source_color, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform highp sampler2DArray _texture_array_normal : hint_normal, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform highp sampler2D noise_texture : source_color, filter_nearest_mipmap_anisotropic, repeat_enable;

uniform float _texture_uv_scale_array[32];
uniform float _texture_detile_array[32];
uniform vec4 _texture_color_array[32];
uniform uint _background_mode = 1u;  // NONE = 0, FLAT = 1, NOISE = 2
uniform uint _mouse_layer = 0x80000000u; // Layer 32

// Public uniforms
uniform float vertex_normals_distance : hint_range(0, 1024) = 128.0;
uniform bool height_blending = true;
uniform float blend_sharpness : hint_range(0, 1) = 0.87;
uniform vec3 macro_variation1 : source_color = vec3(1.);
uniform vec3 macro_variation2 : source_color = vec3(1.);

// Generic noise at 3 scales, which can be used for anything
uniform float noise1_scale : hint_range(0.001, 1.) = 0.04;	// Used for macro variation 1. Scaled up 10x
uniform float noise1_angle : hint_range(0, 6.283) = 0.;
uniform vec2 noise1_offset = vec2(0.5);
uniform float noise2_scale : hint_range(0.001, 1.) = 0.076;	// Used for macro variation 2. Scaled up 10x
uniform float noise3_scale : hint_range(0.001, 1.) = 0.225;  // Used for texture blending edge.

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

// Varyings & Types

struct Material {
	vec4 alb_ht;
	vec4 nrm_rg;
	int base;
	int over;
	float blend;
};

varying vec3 v_vertex;	// World coordinate vertex location
varying flat vec3 v_camera_pos;
varying float v_vertex_xz_dist;
varying flat ivec3 v_region;
varying flat vec2 v_uv_offset;
varying flat vec2 v_uv2_offset;
varying vec3 v_normal;
varying float v_region_border_mask;

////////////////////////
// Vertex
////////////////////////

// Takes in UV world space coordinates, returns ivec3 with:
// XY: (0 to _region_size) coordinates within a region
// Z: layer index used for texturearrays, -1 if not in a region
ivec3 get_region_uv(const vec2 uv) {
	ivec2 pos = ivec2(floor(uv * _region_texel_size)) + (_region_map_size / 2);
	int bounds = int(uint(pos.x | pos.y) < uint(_region_map_size));
	int layer_index = _region_map[ pos.y * _region_map_size + pos.x ] * bounds - 1;
	return ivec3(ivec2(mod(uv,_region_size)), layer_index);
}

// Takes in UV2 region space coordinates, returns vec3 with:
// XY: (0 to 1) coordinates within a region
// Z: layer index used for texturearrays, -1 if not in a region
vec3 get_region_uv2(const vec2 uv2) {
	// Remove Texel Offset to ensure correct region index.
	ivec2 pos = ivec2(floor(uv2 - vec2(_region_texel_size * 0.5))) + (_region_map_size / 2);
	int bounds = int(uint(pos.x | pos.y) < uint(_region_map_size));
	int layer_index = _region_map[ pos.y * _region_map_size + pos.x ] * bounds - 1;
	return vec3(uv2 - _region_locations[layer_index], float(layer_index));
}

// 1 lookup
float get_height(vec2 uv) {
	highp float height = 0.0;
	vec3 region = get_region_uv2(uv);
	if (region.z >= 0.) {
		height = texture(_height_maps, region).r;
	}
 	return height;
}

void vertex() {
	// Get camera pos in world vertex coords
	v_camera_pos = INV_VIEW_MATRIX[3].xyz;

	// Get vertex of flat plane in world coordinates and set world UV
	v_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Camera distance to vertex on flat plane
	v_vertex_xz_dist = length(v_vertex.xz - v_camera_pos.xz);

	// UV coordinates in world space. Values are 0 to _region_size within regions
	UV = round(v_vertex.xz * _vertex_density);

	// UV coordinates in region space + texel offset. Values are 0 to 1 within regions
	UV2 = fma(UV, vec2(_region_texel_size), vec2(0.5 * _region_texel_size));

	// Discard vertices for Holes. 1 lookup
	v_region = get_region_uv(UV);
	uint control = texelFetch(_control_maps, v_region, 0).r;
	bool hole = bool(control >>2u & 0x1u);

	// Show holes to all cameras except mouse camera (on exactly 1 layer)
	if ( !(CAMERA_VISIBLE_LAYERS == _mouse_layer) &&
			(hole || (_background_mode == 0u && (get_region_uv(UV - _region_texel_size) & v_region).z < 0))) {
		VERTEX.x = 0. / 0.;
	} else {
		// Set final vertex height & calculate vertex normals. 3 lookups.
		VERTEX.y = get_height(UV2);
		v_vertex.y = VERTEX.y;
		v_normal = vec3(
			v_vertex.y - get_height(UV2 + vec2(_region_texel_size, 0)),
			_vertex_spacing,
			v_vertex.y - get_height(UV2 + vec2(0, _region_texel_size))
		);
		// Due to a bug caused by the GPUs linear interpolation across edges of region maps,
		// mask region edges and use vertex normals only across region boundaries.
		v_region_border_mask = mod(UV.x + 2.5, _region_size) - fract(UV.x) < 5.0 || mod(UV.y + 2.5, _region_size) - fract(UV.y) < 5.0 ? 1. : 0.;
	}

	// Transform UVs to local to avoid poor precision during varying interpolation.
	v_uv_offset = MODEL_MATRIX[3].xz * _vertex_density;
	UV -= v_uv_offset;
	v_uv2_offset = v_uv_offset * _region_texel_size;
	UV2 -= v_uv2_offset;

	// Convert model space to view space w/ skip_vertex_transform render mode
	VERTEX = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX = (VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	BINORMAL = normalize((MODELVIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz);
	TANGENT = normalize((MODELVIEW_MATRIX * vec4(TANGENT, 0.0)).xyz);
}

////////////////////////
// Fragment
////////////////////////

// 0 - 3 lookups
vec3 get_normal(vec2 uv, out vec3 tangent, out vec3 binormal) {
	float u, v, height;
	vec3 normal;
	// Use vertex normals within radius of vertex_normals_distance, and along region borders.
	if ((v_region_border_mask > 0.5 || v_vertex_xz_dist < vertex_normals_distance) && v_region.z >= 0) {
		normal = normalize(v_normal);
	} else {
		height = get_height(uv);
		u = height - get_height(uv + vec2(_region_texel_size, 0));
		v = height - get_height(uv + vec2(0, _region_texel_size));
		normal = normalize(vec3(u, _vertex_spacing, v));
	}
	tangent = normalize(cross(normal, vec3(0, 0, 1)));
	binormal = normalize(cross(normal, tangent));
	return normal;
}

vec3 unpack_normal(vec4 rgba) {
	vec3 n = fma(rgba.xzy, vec3(2.0, 2.0, -2.0), vec3(-1.0, -1.0, 1.0));
	return n;
}

vec4 pack_normal(vec3 n, float a) {
	return vec4(fma(n.xzy, vec3(0.5, -0.5, 0.5), vec3(0.5)), a);
}

float random(in vec2 xy) {
	return fract(sin(dot(xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 rotate(vec2 v, float cosa, float sina) {
	return vec2(fma(cosa, v.x, - sina * v.y), fma(sina, v.x, cosa * v.y));
}

// Moves a point around a pivot point.
vec2 rotate_around(vec2 point, vec2 pivot, float angle){
	float x = pivot.x + (point.x - pivot.x) * cos(angle) - (point.y - pivot.y) * sin(angle);
	float y = pivot.y + (point.x - pivot.x) * sin(angle) + (point.y - pivot.y) * cos(angle);
	return vec2(x, y);
}

vec4 height_blend(vec4 a_value, float a_height, vec4 b_value, float b_height, float blend) {
	if(height_blending) {
		float ma = max(a_height + (1.0 - blend), b_height + blend) - (1.001 - blend_sharpness);
	    float b1 = max(a_height + (1.0 - blend) - ma, 0.0);
	    float b2 = max(b_height + blend - ma, 0.0);
	    return (a_value * b1 + b_value * b2) / (b1 + b2);
	} else {
		float contrast = 1.0 - blend_sharpness;
		float factor = (blend - contrast) / contrast;
		return mix(a_value, b_value, clamp(factor, 0.0, 1.0));
	}
}

vec2 detiling(vec2 uv, vec2 uv_center, int mat_id, inout float normal_rotation){
	if (_texture_detile_array[mat_id] >= 0.001){
		uv_center = floor(uv_center) + 0.5;
		float detile = fma(random(uv_center), 2.0, -1.0) * TAU * _texture_detile_array[mat_id]; // -180deg to 180deg
		uv = rotate_around(uv, uv_center, detile);
		// Accumulate total rotation for normal rotation
		normal_rotation += detile;
	}
	return uv;
}

vec2 rotate_normal(vec2 normal, float angle) {
	angle = fma(PI, 0.5, angle);
	float new_y = dot(vec2(cos(angle), sin(angle)), normal);
	angle = fma(PI, -0.5, angle);
	float new_x = dot(vec2(cos(angle) ,sin(angle)) ,normal);
	return vec2(new_x, new_y);
}

// 2-4 lookups
void get_material(vec2 base_uv, uint control, ivec3 iuv_center, vec3 normal, out Material out_mat) {
	out_mat = Material(vec4(0.), vec4(0.), 0, 0, 0.0);
	vec2 uv_center = vec2(iuv_center.xy);
	int region = iuv_center.z;

	out_mat.base = int(control >>27u & 0x1Fu);
	out_mat.over = int(control >> 22u & 0x1Fu);
	out_mat.blend = float(control >>14u & 0xFFu) * 0.003921568627450; // 1./255.0

	// Control map scale & rotation, apply to both base and
	// uv_center. Translate uv center to the current region.
	uv_center += _region_locations[region] * _region_size;
	// Define base scale from control map value as array index. 0.5 as baseline.
	float[8] scale_array = { 0.5, 0.4, 0.3, 0.2, 0.1, 0.8, 0.7, 0.6};
	float control_scale = scale_array[(control >>7u & 0x7u)];
	base_uv *= control_scale;
	uv_center *=  control_scale;
	// calculate baseline derivatives
	vec2 ddx = dFdxCoarse(base_uv);
	vec2 ddy = dFdyCoarse(base_uv);
	// Apply global uv rotation from control map.
	float uv_rotation = float(control >>10u & 0xFu) / 16. * TAU;
	base_uv = rotate_around(base_uv, vec2(0), uv_rotation);
	uv_center = rotate_around(uv_center, vec2(0), uv_rotation);

	vec2 matUV = base_uv;
	vec4 albedo_ht = vec4(0.);
	vec4 normal_rg = vec4(0.5f, 0.5f, 1.0f, 1.0f);
	vec4 albedo_far = vec4(0.);
	vec4 normal_far = vec4(0.5f, 0.5f, 1.0f, 1.0f);
	float mat_scale = _texture_uv_scale_array[out_mat.base];
	float normal_angle = uv_rotation;
	vec2 ddx1 = ddx;
	vec2 ddy1 = ddy;

	matUV = detiling(base_uv * mat_scale, uv_center * mat_scale, out_mat.base, normal_angle);
	ddx1 *= mat_scale;
	ddy1 *= mat_scale;
	albedo_ht = textureGrad(_texture_array_albedo, vec3(matUV, float(out_mat.base)), ddx1, ddy1);
	normal_rg = textureGrad(_texture_array_normal, vec3(matUV, float(out_mat.base)), ddx1, ddy1);

	// Unpack & rotate base normal for blending
	normal_rg.xz = unpack_normal(normal_rg).xz;
	normal_rg.xz = rotate_normal(normal_rg.xz, normal_angle);

	// Apply color to base
	albedo_ht.rgb *= _texture_color_array[out_mat.base].rgb;

	// Setup overlay texture to blend
	float mat_scale2 = _texture_uv_scale_array[out_mat.over];
	float normal_angle2 = uv_rotation;
	vec2 matUV2 = detiling(base_uv * mat_scale2, uv_center * mat_scale2, out_mat.over, normal_angle2);
	vec2 ddx2 = ddx * mat_scale2;
	vec2 ddy2 = ddy * mat_scale2;
	vec4 albedo_ht2 = textureGrad(_texture_array_albedo, vec3(matUV2, float(out_mat.over)), ddx2, ddy2);
	vec4 normal_rg2 = textureGrad(_texture_array_normal, vec3(matUV2, float(out_mat.over)), ddx2, ddy2);

	// Though it would seem having the above lookups in this block, or removing the branch would
	// be more optimal, the first introduces artifacts #276, and the second is noticably slower.
	// It seems the branching off dual scaling and the color array lookup is more optimal.
	if (out_mat.blend > 0.f) {
		// Unpack & rotate overlay normal for blending
		normal_rg2.xz = unpack_normal(normal_rg2).xz;
		normal_rg2.xz = rotate_normal(normal_rg2.xz, normal_angle2);

		// Apply color to overlay
		albedo_ht2.rgb *= _texture_color_array[out_mat.over].rgb;

		// Blend overlay and base
		albedo_ht = height_blend(albedo_ht, albedo_ht.a, albedo_ht2, albedo_ht2.a, out_mat.blend);
		normal_rg = height_blend(normal_rg, albedo_ht.a, normal_rg2, albedo_ht2.a, out_mat.blend);
	}

	// Repack normals and return material
	normal_rg = pack_normal(normal_rg.xyz, normal_rg.a);
	out_mat.alb_ht = albedo_ht;
	out_mat.nrm_rg = normal_rg;
	return;
}

float blend_weights(float weight, float detail) {
	weight = smoothstep(0.0, 1.0, weight);
	weight = sqrt(weight * 0.5);
	float result = max(0.1 * weight, fma(10.0, (weight + detail), 1.0f - (detail + 10.0)));
	return result;
}

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

const float W_LIGHT_STEPS = 4.0;

// For whatever reason breaks navigation painting when at the bottom of the
// file lmao
void light() {
	float dotnl = dot(NORMAL, LIGHT);
	float sample_position = clamp(dotnl, 0.01, 1.0);
	vec3 ramp_light = vec3(round(sample_position * W_LIGHT_STEPS) / W_LIGHT_STEPS);
	vec3 diffuse_light = ramp_light.rgb * clamp(LIGHT_COLOR * min(1.0, ATTENUATION), vec3(0,0,0), vec3(1,1,1));
	DIFFUSE_LIGHT = max(diffuse_light * diffuse_light * diffuse_light * diffuse_light, DIFFUSE_LIGHT);
}

void fragment() {
	// Recover UVs
	vec2 uv = UV + v_uv_offset;
	vec2 uv2 = UV2 + v_uv2_offset;

	// Calculate Terrain Normals. 4 lookups
	vec3 w_tangent, w_binormal;
	vec3 w_normal = get_normal(uv2, w_tangent, w_binormal);
	NORMAL = mat3(VIEW_MATRIX) * w_normal;
	TANGENT = mat3(VIEW_MATRIX) * w_tangent;
	BINORMAL = mat3(VIEW_MATRIX) * w_binormal;

	// Idenfity 4 vertices surrounding this pixel
	vec2 texel_pos = uv;
	highp vec2 texel_pos_floor = floor(uv);

	// Create a cross hatch grid of alternating 0/1 horizontal and vertical stripes 1 unit wide in XY
	vec4 mirror = vec4(fract(texel_pos_floor * 0.5) * 2.0, 1.0, 1.0);
	// And the opposite grid in ZW
	mirror.zw = vec2(1.0) - mirror.xy;

	// Get the region and control map ID for the vertices
	ivec3 indexUV[4] = {
		get_region_uv(texel_pos_floor + mirror.xy),
		get_region_uv(texel_pos_floor + mirror.xw),
		get_region_uv(texel_pos_floor + mirror.zy),
		get_region_uv(texel_pos_floor + mirror.zw)
	};

	// Lookup adjacent vertices. 4 lookups
	uint control[4] = {
		texelFetch(_control_maps, indexUV[0], 0).r,
		texelFetch(_control_maps, indexUV[1], 0).r,
		texelFetch(_control_maps, indexUV[2], 0).r,
		texelFetch(_control_maps, indexUV[3], 0).r
	};

	// Get the textures for each vertex. 8-16 lookups (2-4 ea)
	Material mat[4];
	get_material(uv, control[0], indexUV[0], w_normal, mat[0]);
	get_material(uv, control[1], indexUV[1], w_normal, mat[1]);
	get_material(uv, control[2], indexUV[2], w_normal, mat[2]);
	get_material(uv, control[3], indexUV[3], w_normal, mat[3]);

	// Calculate weight for the pixel position between the vertices
	// Bilinear interpolation of difference of uv and floor(uv)
	vec2 weights1 = clamp(texel_pos - texel_pos_floor, 0, 1);
	weights1 = mix(weights1, vec2(1.0) - weights1, mirror.xy);
	vec2 weights0 = vec2(1.0) - weights1;
	// Adjust final weights by texture's height/depth + noise. 1 lookup
	float noise3 = texture(noise_texture, uv*noise3_scale).r;
	vec4 weights;
	weights.x = blend_weights(weights0.x * weights0.y, clamp(mat[0].alb_ht.a + noise3, 0., 1.));
	weights.y = blend_weights(weights0.x * weights1.y, clamp(mat[1].alb_ht.a + noise3, 0., 1.));
	weights.z = blend_weights(weights1.x * weights0.y, clamp(mat[2].alb_ht.a + noise3, 0., 1.));
	weights.w = blend_weights(weights1.x * weights1.y, clamp(mat[3].alb_ht.a + noise3, 0., 1.));
	float weight_sum = weights.x + weights.y + weights.z + weights.w;
	float weight_inv = 1.0 / weight_sum;

	// Weighted average of albedo & height
	vec4 albedo_height = weight_inv * (
		mat[0].alb_ht * weights.x +
		mat[1].alb_ht * weights.y +
		mat[2].alb_ht * weights.z +
		mat[3].alb_ht * weights.w );

	// Weighted average of normal & rough
	vec4 normal_rough = weight_inv * (
		mat[0].nrm_rg * weights.x +
		mat[1].nrm_rg * weights.y +
		mat[2].nrm_rg * weights.z +
		mat[3].nrm_rg * weights.w );

	// Determine if we're in a region or not (region_uv.z>0)
	vec3 region_uv = get_region_uv2(uv2);

	// Colormap. 1 lookup
	vec4 color_map = vec4(1., 1., 1., .5);
	if (region_uv.z >= 0.) {
		float lod = textureQueryLod(_color_maps, uv2.xy).y;
		color_map = textureLod(_color_maps, region_uv, lod);
	}

	// Macro variation. 2 Lookups
	float noise1 = texture(noise_texture, rotate(uv*noise1_scale * .1, cos(noise1_angle), sin(noise1_angle)) + noise1_offset).r;
	float noise2 = texture(noise_texture, uv*noise2_scale * .1).r;
	vec3 macrov = mix(macro_variation1, vec3(1.), clamp(noise1 + v_vertex_xz_dist * .0002, 0., 1.));
	macrov *= mix(macro_variation2, vec3(1.), clamp(noise2 + v_vertex_xz_dist * .0002, 0., 1.));

	// Wetness/roughness modifier, converting 0-1 range to -1 to 1 range
	float roughness = fma(color_map.a - 0.5, 2.0, normal_rough.a);

	// Apply PBR
	ALBEDO = albedo_height.rgb * color_map.rgb * macrov;
	ROUGHNESS = roughness;
	SPECULAR = 1. - normal_rough.a;
	NORMAL_MAP = normal_rough.rgb;
	NORMAL_MAP_DEPTH = 1.0;

	// Draw circles on positions provided by circle_positions texture
	//
	// Fuck performance, to hell with decals
	for (float i = 1.5; i < circle_count; i += 1.0) {
		const float half_width = 0.015;
		vec2 circle_uv = vec2(i / circle_count, 0.5);
		vec4 pos = texture(circle_positions, circle_uv);
		float pos_dist = distance(pos.xyz, v_vertex);
		if (pos_dist < pos.w + half_width) {
			float line_dist = pos_dist - pos.w;
			float abs_line_dist = abs(line_dist);
			vec4 extras = texture(circle_extras, circle_uv);
			float circle_border_a = float(abs_line_dist < half_width);
			float inside_a = mix(0., pow(pos_dist / pos.w, 2), extras.y) * 0.05;
			vec4 cl = texture(circle_colors, circle_uv);
			// Calculate clockwise angle for dashed
			vec2 ptn = pos.xz - v_vertex.xz;
			float angle = atan(ptn.y / ptn.x) / PI * extras.x;
			float dashed_a = float(fract(angle + TIME) * float(bool(extras.x)) < 0.5);
			ALBEDO = mix(ALBEDO, cl.xyz, max(circle_border_a, inside_a) * dashed_a * cl.a);
		}
	}

	// Project dashed line defined by line_vertices texture.
	//
	// todo: It was fun to write, but introduce some node which creates the
	// line out of planes that copy the terrain
	float total_distance = 0.;
	float min_distance = 1000.;
	float prev_sum = 0.;
	for (uint i = 1u; i < line_size; i++) {
		vec2 segment_start = line_vertices[i - 1u];
		vec2 segment_end = line_vertices[i];
		vec2 nearest_points_on_line = find_nearest_point_on_line(segment_start, segment_end, v_vertex.xz);
		float line_len = distance(segment_start, segment_end);
		float on_line_dist = distance(segment_start, nearest_points_on_line);
		float current_distance = distance(nearest_points_on_line, v_vertex.xz);
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
		ALBEDO = mix(ALBEDO, line_color, line_alpha);
	}
}
