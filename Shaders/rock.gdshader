shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.35, 0.33, 0.3);
uniform vec3 dark_color : source_color = vec3(0.2, 0.18, 0.16);
uniform vec3 highlight_color : source_color = vec3(0.5, 0.48, 0.44);
uniform float roughness : hint_range(0.0, 1.0) = 0.95;
uniform float noise_scale : hint_range(1.0, 20.0) = 8.0;
uniform float color_variation : hint_range(0.0, 1.0) = 0.4;

// Simple noise function
float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	
	return mix(
		mix(mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), f.x),
			mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
			mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Generate noise for color variation
	float n = fbm(world_pos * noise_scale);
	float n2 = fbm(world_pos * noise_scale * 0.5 + 100.0);
	
	// Mix between dark, base, and highlight based on noise
	vec3 color = base_color;
	color = mix(color, dark_color, smoothstep(0.3, 0.5, n) * color_variation);
	color = mix(color, highlight_color, smoothstep(0.6, 0.8, n2) * color_variation * 0.5);
	
	// Add subtle moss tint in crevices (lower areas)
	float moss = smoothstep(0.4, 0.6, n) * smoothstep(0.3, 0.0, NORMAL.y) * 0.3;
	color = mix(color, vec3(0.15, 0.25, 0.1), moss);
	
	ALBEDO = color;
	ROUGHNESS = roughness + n * 0.05;
	METALLIC = 0.0;
}
