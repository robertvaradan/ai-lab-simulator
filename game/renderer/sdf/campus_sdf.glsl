#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, rgba8) uniform restrict writeonly image2D output_image;

layout(push_constant, std430) uniform Params {
	vec4 render_data; // width, height, state, time
	vec4 camera_data; // orbit, pitch, ortho scale, reserved
} params;

const float MAX_DISTANCE = 70.0;
const float SURFACE_EPSILON = 0.018;
const int MAX_STEPS = 88;
const vec3 SKY_TOP = vec3(0.035, 0.064, 0.083);
const vec3 SKY_BOTTOM = vec3(0.095, 0.135, 0.145);

float sd_box(vec3 point, vec3 half_size) {
	vec3 offset = abs(point) - half_size;
	return length(max(offset, 0.0)) + min(max(offset.x, max(offset.y, offset.z)), 0.0);
}

float sd_round_box(vec3 point, vec3 half_size, float radius) {
	vec3 offset = abs(point) - half_size + radius;
	return length(max(offset, 0.0)) + min(max(offset.x, max(offset.y, offset.z)), 0.0) - radius;
}

float sd_cylinder_y(vec3 point, vec2 size) {
	vec2 offset = abs(vec2(length(point.xz), point.y)) - size;
	return min(max(offset.x, offset.y), 0.0) + length(max(offset, 0.0));
}

float sd_capsule(vec3 point, vec3 start, vec3 end, float radius) {
	vec3 pa = point - start;
	vec3 ba = end - start;
	float projection = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * projection) - radius;
}

vec2 union_hit(vec2 current, float distance, float material_id) {
	return distance < current.x ? vec2(distance, material_id) : current;
}

vec2 map_growth(vec3 point, vec2 hit) {
	for (int index = 0; index < 3; index++) {
		float x = -5.9 + float(index) * 1.15;
		vec3 pod_point = point - vec3(x, 0.35, 3.25);
		hit = union_hit(hit, sd_round_box(pod_point, vec3(0.46, 0.62, 0.62), 0.16), 4.0);
		hit = union_hit(hit, sd_cylinder_y(point - vec3(x, 1.18, 3.25), vec2(0.24, 0.28)), 9.0);
	}
	hit = union_hit(hit, sd_round_box(point - vec3(-3.65, 3.35, -0.45), vec3(1.25, 0.12, 0.78), 0.08), 4.0);
	return hit;
}

vec2 map_overload(vec3 point, vec2 hit) {
	for (int index = 0; index < 4; index++) {
		float z = -0.5 + float(index) * 0.78;
		hit = union_hit(hit, sd_cylinder_y(point - vec3(-3.75, 3.15, z), vec2(0.19, 0.8)), 5.0);
	}
	hit = union_hit(hit, sd_capsule(point, vec3(-5.4, 1.2, 1.45), vec3(-2.1, 1.2, 1.45), 0.14), 5.0);
	hit = union_hit(hit, sd_capsule(point, vec3(-2.1, 1.2, 1.45), vec3(-2.1, 2.65, 1.45), 0.14), 5.0);
	hit = union_hit(hit, sd_round_box(point - vec3(-1.35, 0.22, 3.1), vec3(1.45, 0.18, 0.12), 0.05), 6.0);
	return hit;
}

vec2 map_scrutiny(vec3 point, vec2 hit) {
	for (int index = 0; index < 5; index++) {
		float x = -2.35 + float(index) * 1.15;
		hit = union_hit(hit, sd_round_box(point - vec3(x, 0.38, 4.75), vec3(0.04, 0.48, 0.04), 0.02), 6.0);
	}
	hit = union_hit(hit, sd_round_box(point - vec3(0.0, 0.86, 4.75), vec3(2.65, 0.04, 0.04), 0.02), 6.0);
	hit = union_hit(hit, sd_round_box(point - vec3(3.75, 0.68, 2.75), vec3(0.72, 0.72, 0.12), 0.08), 8.0);
	hit = union_hit(hit, sd_round_box(point - vec3(3.75, 1.45, 2.75), vec3(0.28, 0.08, 0.12), 0.04), 9.0);
	return hit;
}

vec2 map_laboratory(vec3 point, vec2 hit) {
	// Research headquarters: a low institutional block plus a luminous upper lab.
	hit = union_hit(hit, sd_round_box(point - vec3(-3.75, 1.15, -0.55), vec3(2.05, 1.15, 1.65), 0.18), 2.0);
	hit = union_hit(hit, sd_round_box(point - vec3(-3.75, 2.58, -0.55), vec3(1.42, 0.28, 1.1), 0.12), 3.0);
	hit = union_hit(hit, sd_round_box(point - vec3(-5.85, 0.75, -0.55), vec3(0.18, 0.74, 0.84), 0.07), 8.0);
	return hit;
}

vec2 map_scene(vec3 point) {
	vec2 hit = vec2(1000.0, 0.0);

	// Carved-out campus plinth, road, and path network.
	hit = union_hit(hit, sd_round_box(point - vec3(0.0, -0.66, 0.0), vec3(8.75, 0.72, 6.0), 0.38), 1.0);
	hit = union_hit(hit, sd_round_box(point - vec3(0.0, 0.03, 4.55), vec3(7.7, 0.035, 0.72), 0.08), 7.0);
	hit = union_hit(hit, sd_round_box(point - vec3(-0.3, 0.055, 1.95), vec3(0.72, 0.04, 2.3), 0.08), 7.0);

	int state = int(params.render_data.z + 0.5);
	// empty=0 is land only. growth=1, overload=2, scrutiny=3 show the HQ laboratory.
	// HQ must not present Data Center or Application building mass.
	if (state != 0) {
		hit = map_laboratory(point, hit);
	}
	if (state == 1) {
		hit = map_growth(point, hit);
	} else if (state == 2) {
		hit = map_overload(point, hit);
	} else if (state == 3) {
		hit = map_scrutiny(point, hit);
	}
	return hit;
}

vec3 scene_normal(vec3 point) {
	vec2 epsilon = vec2(0.012, -0.012);
	return normalize(
		epsilon.xyy * map_scene(point + epsilon.xyy).x +
		epsilon.yyx * map_scene(point + epsilon.yyx).x +
		epsilon.yxy * map_scene(point + epsilon.yxy).x +
		epsilon.xxx * map_scene(point + epsilon.xxx).x
	);
}

float soft_shadow(vec3 origin, vec3 direction) {
	float visibility = 1.0;
	float travel = 0.08;
	for (int step = 0; step < 18; step++) {
		float distance = map_scene(origin + direction * travel).x;
		visibility = min(visibility, 12.0 * distance / travel);
		travel += clamp(distance, 0.04, 0.55);
		if (distance < 0.004 || travel > 16.0) {
			break;
		}
	}
	return clamp(visibility, 0.18, 1.0);
}

float ambient_occlusion(vec3 point, vec3 normal) {
	float occlusion = 0.0;
	float weight = 1.0;
	for (int sample_index = 1; sample_index <= 4; sample_index++) {
		float distance = 0.12 * float(sample_index);
		occlusion += (distance - map_scene(point + normal * distance).x) * weight;
		weight *= 0.58;
	}
	return clamp(1.0 - occlusion * 1.7, 0.25, 1.0);
}

vec3 palette(float material_id, vec3 point) {
	if (material_id < 1.5) {
		return vec3(0.29, 0.33, 0.32);
	}
	if (material_id < 2.5) {
		vec3 graphite = vec3(0.095, 0.125, 0.135);
		float floor_band = step(0.68, fract(point.y * 1.18 + 0.08));
		float bay_band = step(0.57, fract((point.x + point.z * 0.55) * 0.72));
		float window = floor_band * bay_band;
		return mix(graphite, vec3(0.16, 0.43, 0.46), window * 0.72);
	}
	if (material_id < 3.5) {
		return vec3(0.14, 0.58, 0.61);
	}
	if (material_id < 4.5) {
		return vec3(0.19, 0.72, 0.53);
	}
	if (material_id < 5.5) {
		return vec3(0.97, 0.39, 0.16);
	}
	if (material_id < 6.5) {
		return vec3(0.88, 0.12, 0.14);
	}
	if (material_id < 7.5) {
		return vec3(0.055, 0.068, 0.071);
	}
	if (material_id < 8.5) {
		return vec3(0.62, 0.67, 0.64);
	}
	return vec3(0.92, 0.71, 0.22);
}

vec3 shade_surface(vec3 point, vec3 ray_direction, float material_id) {
	vec3 normal = scene_normal(point);
	vec3 light_direction = normalize(vec3(-0.65, 0.82, 0.48));
	float diffuse = max(dot(normal, light_direction), 0.0);
	float shadow = soft_shadow(point + normal * 0.035, light_direction);
	float ao = ambient_occlusion(point, normal);
	float rim = pow(1.0 - max(dot(normal, -ray_direction), 0.0), 3.0);
	vec3 base = palette(material_id, point);
	vec3 lit = base * (0.32 + 0.78 * diffuse * shadow) * ao;
	lit += vec3(0.12, 0.22, 0.23) * max(normal.y, 0.0) * 0.28;
	lit += vec3(0.22, 0.43, 0.44) * rim * 0.18;
	if (material_id > 8.5) {
		lit += base * 0.55;
	}
	return lit;
}

void main() {
	ivec2 pixel = ivec2(gl_GlobalInvocationID.xy);
	ivec2 resolution = ivec2(params.render_data.xy);
	if (pixel.x >= resolution.x || pixel.y >= resolution.y) {
		return;
	}

	vec2 uv = (vec2(pixel) + 0.5) / vec2(resolution);
	// Compute invocation (0,0) is the top-left texel. Flip Y so +uv.y is camera-up.
	uv.y = 1.0 - uv.y;
	uv = uv * 2.0 - 1.0;
	uv.x *= float(resolution.x) / float(resolution.y);

	float orbit = params.camera_data.x;
	float pitch = params.camera_data.y;
	float scale = params.camera_data.z;
	vec3 forward = normalize(vec3(-cos(orbit) * cos(pitch), -sin(pitch), -sin(orbit) * cos(pitch)));
	vec3 right = normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
	vec3 up = normalize(cross(right, forward));
	vec3 target = vec3(0.0, 1.0, 0.0);
	vec3 ray_origin = target - forward * 28.0 + right * uv.x * scale + up * uv.y * scale;
	vec3 ray_direction = forward;

	float travel = 0.0;
	vec2 hit = vec2(1000.0, 0.0);
	for (int step = 0; step < MAX_STEPS; step++) {
		vec3 point = ray_origin + ray_direction * travel;
		hit = map_scene(point);
		if (hit.x < SURFACE_EPSILON * (1.0 + travel * 0.018) || travel > MAX_DISTANCE) {
			break;
		}
		travel += max(hit.x * 0.88, 0.012);
	}

	vec3 sky = mix(SKY_BOTTOM, SKY_TOP, clamp(uv.y * 0.5 + 0.5, 0.0, 1.0));
	vec3 color = sky;
	if (travel <= MAX_DISTANCE && hit.x < 0.12) {
		vec3 point = ray_origin + ray_direction * travel;
		color = shade_surface(point, ray_direction, hit.y);
		float fog = smoothstep(26.0, 60.0, travel);
		color = mix(color, sky, fog * 0.42);
	}

	float vignette = 1.0 - 0.16 * dot(uv * vec2(0.58, 0.8), uv * vec2(0.58, 0.8));
	color *= clamp(vignette, 0.72, 1.0);
	color = pow(max(color, 0.0), vec3(0.86));
	imageStore(output_image, pixel, vec4(color, 1.0));
}

