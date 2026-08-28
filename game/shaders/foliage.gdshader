shader_type spatial;

// Hedge and tree crowns. One palette albedo. Depth from triplanar normals.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_disabled;

group_uniforms Color;
uniform vec3 albedo_color : source_color = vec3(0.149, 0.286, 0.212);

group_uniforms Triplanar;
uniform float noise_scale : hint_range(0.1, 24.0) = 4.5;
uniform float blend_sharpness : hint_range(1.0, 16.0) = 5.0;
uniform float normal_strength : hint_range(0.0, 2.5) = 0.85;

group_uniforms Depth;
uniform float wrap_amount : hint_range(0.0, 1.0) = 0.32;
uniform float catch_strength : hint_range(0.0, 1.5) = 0.48;
uniform float catch_power : hint_range(1.0, 12.0) = 3.2;
uniform float shade_floor : hint_range(0.0, 0.5) = 0.2;

group_uniforms Surface;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.94;

varying vec3 world_position;
varying vec3 world_normal;

float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	mat2 rot = mat2(vec2(0.8, -0.6), vec2(0.6, 0.8));
	for (int i = 0; i < 4; i++) {
		value += amplitude * value_noise(p);
		p = rot * p * 2.05;
		amplitude *= 0.5;
	}
	return value;
}

float triplanar_noise(vec3 pos, vec3 normal, float scale, float sharpness) {
	vec3 blend = pow(abs(normal), vec3(sharpness));
	blend /= max(blend.x + blend.y + blend.z, 0.0001);
	float nx = fbm(pos.zy * scale);
	float ny = fbm(pos.xz * scale);
	float nz = fbm(pos.xy * scale);
	return nx * blend.x + ny * blend.y + nz * blend.z;
}

vec3 triplanar_normal(vec3 pos, vec3 normal, float scale, float sharpness, float strength) {
	float epsilon = 0.04;
	float h = triplanar_noise(pos, normal, scale, sharpness);
	float hx = triplanar_noise(pos + vec3(epsilon, 0.0, 0.0), normal, scale, sharpness);
	float hy = triplanar_noise(pos + vec3(0.0, epsilon, 0.0), normal, scale, sharpness);
	float hz = triplanar_noise(pos + vec3(0.0, 0.0, epsilon), normal, scale, sharpness);
	vec3 gradient = vec3(hx - h, hy - h, hz - h) / epsilon;
	return normalize(normal - gradient * strength);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 perturbed_world = triplanar_normal(
		world_position,
		normalize(world_normal),
		noise_scale,
		blend_sharpness,
		normal_strength
	);
	NORMAL = normalize((VIEW_MATRIX * vec4(perturbed_world, 0.0)).xyz);

	ALBEDO = albedo_color;
	ROUGHNESS = roughness_value;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}

void light() {
	float ndotl = dot(NORMAL, LIGHT);
	float wrap = clamp((ndotl + wrap_amount) / (1.0 + wrap_amount), 0.0, 1.0);
	float shaped = pow(max(wrap, 0.0), 1.25);
	shaped = max(shaped, shade_floor * (0.55 + 0.45 * wrap));

	float half_lambert = clamp(ndotl * 0.5 + 0.5, 0.0, 1.0);
	float catch_term = pow(half_lambert, catch_power) * catch_strength;
	catch_term *= smoothstep(0.15, 0.85, wrap);

	vec3 light_contrib = ATTENUATION * LIGHT_COLOR;
	DIFFUSE_LIGHT += light_contrib * (shaped + catch_term) * ALBEDO;
}
