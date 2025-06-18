shader_type spatial;
render_mode unshaded,shadows_disabled,cull_disabled,fog_disabled;

uniform sampler2D screen_texture: source_color, hint_screen_texture;
uniform sampler2D noise: source_color;
uniform sampler2D overlay: source_color;
uniform sampler2D gradient: source_color;
uniform sampler2D texture_albedo: source_color,filter_nearest;

#define BRUSH_SIZE 3.
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
	uv -= .5;
	//uv *= 1. - (sin(iTime * .25) * .5 + .5) * .4;
	uv += .5;
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

vec3 kuwahara(vec2 uv, float brushSize) {
	vec4 p = vec4(dFdx(uv.x), dFdy(uv.y), -dFdy(uv.y), 0.);

	// 5x5
	/*
	A  A  AB   B  B
	A  A  AB   B  B
	AC AC ABCD BD BD
	C  C  CD   D  D
	C  C  CD   D  D
	*/
	float angle = 1.;

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

void fragment()
{
	// Normalized pixel coordinates (from 0 to 1)
	vec2 uv = SCREEN_UV;

	float n = texture(noise, SCREEN_UV).x;
	vec3 col = kuwahara(uv, BRUSH_SIZE * n);

	col = contrast(col, 1.05);

	// Output to screen
	ALBEDO = col;
	float a = texture(screen_texture, uv).a;

	vec3 bg = texture(texture_albedo, SCREEN_UV).rgb;
	// float depth = texture(depth_texture, SCREEN_UV).x;
	float lines = texture(overlay, SCREEN_UV).x;
	vec3 g = texture(gradient, SCREEN_UV).rgb;
	// vec4 screen = texture(screen_texture, SCREEN_UV);
	// vec4 screen = sample_blur(screen_texture, SCREEN_UV, VIEWPORT_SIZE, vec2(5.) * n);
	// vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	// vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	// view.xyz /= view.w;
	// float linear_depth = -view.z;
	// vec4 world = CAMERA * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	// vec3 world_position = world.xyz / world.w;

	vec3 darkened = vec3(min(g.r, ALBEDO.r), min(g.g, ALBEDO.g), min(g.b, ALBEDO.b));
	ALBEDO = mix(ALBEDO, darkened, 0.5);
	ALBEDO = mix(ALBEDO, clamp(ALBEDO + lines - 1., 0., 1.), 0.6 * n);
	ALBEDO = mix(bg, ALBEDO, a);

}
