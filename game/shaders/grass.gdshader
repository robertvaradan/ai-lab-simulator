shader_type spatial;

// Soft putting-green lawn. Triplanar world noise keeps boxes even without UVs.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_disabled;

group_uniforms Color;
uniform vec3 albedo_lit : source_color = vec3(0.30, 0.42, 0.28);
uniform vec3 albedo_shade : source_color = vec3(0.18, 0.28, 0.20);
uniform float color_blend : hint_range(0.0, 1.0) = 0.42;

group_uniforms Triplanar;
uniform float noise_scale : hint_range(0.1, 24.0) = 3.2;
uniform float noise_strength : hint_range(0.0, 0.5) = 0.06;
uniform float blend_sharpness : hint_range(1.0, 16.0) = 6.0;

group_uniforms Velvet;
uniform float wrap_amount : hint_range(0.0, 1.0) = 0.62;
uniform float velvet_strength : hint_range(0.0, 1.0) = 0.18;
uniform float velvet_power : hint_range(1.0, 8.0) = 2.8;
uniform float evenness : hint_range(0.0, 1.0) = 0.72;

group_uniforms Surface;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.97;

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
		p = rot * p * 2.02;
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

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float grain = triplanar_noise(world_position, world_normal, noise_scale, blend_sharpness);
	float variation = (grain - 0.5) * noise_strength;
	vec3 base = mix(albedo_shade, albedo_lit, color_blend);
	base = clamp(base + vec3(variation), vec3(0.0), vec3(1.0));

	// Flatten local contrast so the lawn reads soft and even.
	base = mix(base, vec3(dot(base, vec3(0.299, 0.587, 0.114))), evenness * 0.22);
	base = mix(vec3(dot(base, vec3(0.333))), base, 1.0 - evenness * 0.15);

	ALBEDO = base;
	ROUGHNESS = roughness_value;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}

void light() {
	float ndotl = dot(NORMAL, LIGHT);
	float wrap = clamp((ndotl + wrap_amount) / (1.0 + wrap_amount), 0.0, 1.0);
	// Soft wrap keeps putts looking velvety instead of hard-shaded.
	wrap = mix(wrap, smoothstep(0.0, 1.0, wrap), 0.55);

	float view_term = 1.0 - abs(dot(NORMAL, VIEW));
	float velvet = pow(clamp(view_term, 0.0, 1.0), velvet_power) * velvet_strength;
	velvet *= clamp(ndotl * 0.5 + 0.5, 0.0, 1.0);

	vec3 light_contrib = ATTENUATION * LIGHT_COLOR;
	DIFFUSE_LIGHT += light_contrib * wrap * ALBEDO;
	SPECULAR_LIGHT += light_contrib * velvet * ALBEDO;
}
