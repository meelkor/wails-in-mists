// Kuwahara algorithm implementation taken from
// https://www.shadertoy.com/view/tlX3RX
//
// TODO: Missing the median pass since I can't simply do another screen-reading pass
// in 3D. Consider making this into compute shader or use the composer thing.
//
// TODO: Improvement ideas:
//  - use depth texture to highlight edges
//  - use the noise better to make the filter feel more dynamic
//  - make the oil effect more "directional"
//  - the tentacles thing is dumb

shader_type spatial;
render_mode unshaded,shadows_disabled,cull_disabled,fog_disabled;

uniform sampler2D screen_texture: source_color, hint_screen_texture;
uniform sampler2D noise_texture: source_color;
uniform sampler2D overlay_texture: source_color;
uniform sampler2D gradient_texture: source_color;
uniform sampler2D texture_albedo: source_color,filter_nearest;
uniform sampler2D texture_tentacles: source_color,filter_nearest;

#define BRUSH_SIZE 1.5
#define WINDOW_SIZE 5
#define DEPTH_PER_CHANNEL 128
const int REGION_SIZE = (WINDOW_SIZE + 1) / 2;
const int REGION_N = REGION_SIZE * REGION_SIZE;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

vec3 contrast(vec3 col, float contrast) {
	return (col - .5) * contrast + .5;
}

mat2 rotate(float a){
	return mat2(
		vec2(cos(a), -sin(a)),
		vec2(sin(a), cos(a))
	);
}

float rand(vec2 uv){
	return fract(sin(dot(vec2(12.9898,78.233), uv)) * 43758.5453123);
}

// http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
vec3 rgb2hsv(vec3 c)
{
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
vec3 hsv2rgb(vec3 c)
{
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec4 tex(vec2 uv){
	vec4 col = texture(screen_texture, uv);
	float depth = float(DEPTH_PER_CHANNEL);

	col.r = floor(col.r * depth) / depth;
	col.g = floor(col.g * depth) / depth;
	col.b = floor(col.b * depth) / depth;
	col.a = rgb2hsv(col.rgb).b;

	return col;
}

float regionMeanValue(vec4 vals[REGION_N]) {
	float sum = 0.0;

	for (int i = 0; i < REGION_N; ++i){
		sum += vals[i].a;
	}
	return sum / float(REGION_N);
}

vec3 regionMean(vec4 vals[REGION_N]) {
	vec3 sum = vec3(0);
	for (int i = 0; i < REGION_N; ++i){
		sum += vals[i].rgb;
	}
	return vec3(sum / float(REGION_N));
}

float regionStandardDeviation(vec4 vals[REGION_N], float mean) {
	float sum = 0.;

	for (int i = 0; i < REGION_N; ++i){
		float val = vals[i].a - mean;
		sum += val * val;
	}
	return sqrt(sum / float(REGION_N - 1));

}

vec3 kuwahara(vec2 uv, float brushSize, float angle) {
	vec4 p = vec4(dFdx(uv.x), dFdy(uv.y), -dFdy(uv.y), 0.);
	mat2 a = rotate(uv.x + uv.y + rand(uv) + angle) * BRUSH_SIZE;

	vec4 regVal[REGION_N];
	for (int y = 0; y < REGION_SIZE; ++y){
		for (int x = 0; x < REGION_SIZE; ++x){
			regVal[y * REGION_SIZE + x] = tex(uv + a * vec2(-p.x * float(x), -p.y * float(y)));
		}

	}

	float meanValueA = regionMeanValue(regVal);
	vec3 meanA = regionMean(regVal);
	float standardDeviationA = regionStandardDeviation(regVal, meanValueA);

	for (int y = 0; y < REGION_SIZE; ++y){
		for (int x = 0; x < REGION_SIZE; ++x){
			regVal[y * REGION_SIZE + x] = tex(uv + a * vec2(p.x * float(x), -p.y * float(y)));
		}
	}


	float meanValueB = regionMeanValue(regVal);
	vec3 meanB = regionMean(regVal);
	float standardDeviationB = regionStandardDeviation(regVal, meanValueB);

	for (int y = 0; y < REGION_SIZE; ++y){
		for (int x = 0; x < REGION_SIZE; ++x){
			regVal[y * REGION_SIZE + x] = tex(uv + a * vec2(-p.x * float(x), p.y * float(y)));
		}
	}

	float meanValueC = regionMeanValue(regVal);
	vec3 meanC = regionMean(regVal);
	float standardDeviationC = regionStandardDeviation(regVal, meanValueC);

	for (int y = 0; y < REGION_SIZE; ++y){
		for (int x = 0; x < REGION_SIZE; ++x){
			regVal[y * REGION_SIZE + x] = tex(uv + a * vec2(p.x * float(x), p.y * float(y)));
		}
	}

	float meanValueD = regionMeanValue(regVal);
	vec3 meanD = regionMean(regVal);
	float standardDeviationD = regionStandardDeviation(regVal, meanValueD);

	float mostHomogeneous = min(standardDeviationA, min(standardDeviationB, min(standardDeviationC, standardDeviationD)));
	vec3 outMean = vec3(0);
	if (mostHomogeneous == standardDeviationA) outMean = meanA;
	if (mostHomogeneous == standardDeviationB) outMean = meanB;
	if (mostHomogeneous == standardDeviationC) outMean = meanC;
	if (mostHomogeneous == standardDeviationD) outMean = meanD;

	return outMean;
}

vec3 colorDodge(vec3 target, vec3 blend) {
    return vec3(
		blend.r == 1.0 ? blend.r : target.r / (1.0 - blend.r),
		blend.g == 1.0 ? blend.g : target.g / (1.0 - blend.g),
		blend.b == 1.0 ? blend.b : target.b / (1.0 - blend.b)
	);
}

void fragment()
{
	float noise = texture(noise_texture, SCREEN_UV).x;
	float a = texture(screen_texture, SCREEN_UV).a;
	vec3 bg = texture(texture_albedo, SCREEN_UV).rgb;
	float lines = texture(overlay_texture, SCREEN_UV).x;
	vec3 gradient = texture(gradient_texture, SCREEN_UV).rgb;
	vec4 tentacles = texture(texture_tentacles, SCREEN_UV);
	ALBEDO = kuwahara(SCREEN_UV + lines * 0.025, BRUSH_SIZE * noise, noise);

	ALBEDO = contrast(ALBEDO, 1.058);
	vec3 darkened_gradient = vec3(min(gradient.r, ALBEDO.r), min(gradient.g, ALBEDO.g), min(gradient.b, ALBEDO.b));
	ALBEDO = mix(ALBEDO, darkened_gradient, (1. - lines) * 0.8 * noise);
	ALBEDO = mix(ALBEDO, clamp(ALBEDO + lines - 1., 0., 1.), 0.6 * noise);
	ALBEDO = mix(bg, ALBEDO, a);
	ALBEDO = mix(ALBEDO, ALBEDO * tentacles.rgb, tentacles.a);
}
