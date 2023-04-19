shader_type canvas_item;

uniform vec3 cam_pos = vec3(8.0,8.0,9.0);
uniform mat3 cam_mat = mat3(0.0);
uniform float width = 0.3;
uniform float height = 0.1;
uniform float fov = 90.0;
uniform float shimmer_speed = 0.1;

const float COLLISION_THRESHOLD = 13e-4;
const int MAX_ITER = 128;
const float UNIVERSE_SIZE = 16.0;
const float RUNAWAY_THRESHOLD = 24.0;
const float PI = 3.1415926535897932384626433832795;

// http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void sphere_fold(inout vec3 p, inout float dz) {
	float r2 = p.x * p.x + p.y * p.y + p.z * p.z;
	if (r2 < 0.25) {
		p *= 0.5 / 0.25;
		dz *= 0.5 / 0.25;
	} else if (r2 < 0.5) {
		p *= 0.5 / r2;
		dz *= 0.5 / r2;
	}
}

void box_fold(inout vec3 p) {
	p.x = clamp(p.x, -0.5, 0.5) * 2.0 - p.x;
	p.y = clamp(p.y, -0.5, 0.5) * 2.0 - p.y;
	p.z = clamp(p.z, -0.5, 0.5) * 2.0 - p.z;
}

float mandelbox_de(vec3 p) {
	//p = mod(p, UNIVERSE_SIZE) - vec3(8.0);
	float dz = 1.0;
	vec3 o = p;
	float scale = sin(TIME / 2.0) * 0.35 + 2.25;
	for (int i = 0; i < 10; i++) {
		box_fold(p);
		sphere_fold(p, dz);
		p = p * scale + o;
		dz = dz * scale + 1.0;
	}
	return length(p) / dz;
}

int march(inout vec3 ray_pos, vec3 ray_dir, int max_iter, inout float closest_dist) {
	float dist = UNIVERSE_SIZE;
	int iter = 0;
	for (int i = 0; i < 128; i++) {
		dist = abs(mandelbox_de(ray_pos));
		closest_dist = min(closest_dist, dist);
		ray_pos += ray_dir * dist;
		
		if (dist > RUNAWAY_THRESHOLD) {
			iter = 128;
			break;
		}
		
		if (dist < COLLISION_THRESHOLD)
			break;
		iter++;
	}
	return iter;
}

// https://www.scratchapixel.com/lessons/3d-basic-rendering/ray-tracing-generating-camera-rays/generating-camera-rays.html
void fragment() {
	vec3 ray_pos = cam_pos;
	float aspect = width / height;
	float pX = (2.0 * UV.x - 1.0) * tan(fov / 2.0 * PI / 180.0) * aspect;
	float pY = (1.0 - 2.0 * UV.y * tan(fov / 2.0 * PI / 180.0));
	vec3 ray_dir = vec3(pX, pY, -1);
	ray_dir = cam_mat * normalize(ray_dir);
	
	float closest_dist = UNIVERSE_SIZE;
	int iter = march(ray_pos, ray_dir, MAX_ITER, closest_dist);
	vec3 col = hsv2rgb(vec3(float(iter) / float(MAX_ITER) + TIME * shimmer_speed, 0.65, 1.0));
	if (iter < MAX_ITER) {
		COLOR.rgb =  col;
	} else {
		float glow = 1.0 - pow(closest_dist, 0.25);
		COLOR.rgb = col * pow(glow, 2.5);
	}
}