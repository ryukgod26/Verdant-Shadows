shader_type spatial;
render_mode cull_back, diffuse_burley;

uniform vec3 dirt_color : source_color = vec3(0.18, 0.12, 0.08);
uniform vec3 dark_dirt : source_color = vec3(0.1, 0.07, 0.04);
uniform vec3 moss_color : source_color = vec3(0.12, 0.22, 0.08);
uniform vec3 leaf_color : source_color = vec3(0.25, 0.15, 0.08);
uniform float noise_scale : hint_range(1.0, 30.0) = 12.0;
uniform float moss_amount : hint_range(0.0, 1.0) = 0.3;
uniform float leaf_amount : hint_range(0.0, 1.0) = 0.2;
uniform float roughness : hint_range(0.0, 1.0) = 0.95;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 5; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 uv = world_pos.xz;
	
	// Base dirt with variation
	float n1 = fbm(uv * noise_scale);
	float n2 = fbm(uv * noise_scale * 0.5 + 50.0);
	float n3 = fbm(uv * noise_scale * 2.0 + 100.0);
	
	vec3 color = mix(dirt_color, dark_dirt, smoothstep(0.3, 0.7, n1));
	
	// Moss patches
	float moss_mask = smoothstep(0.5, 0.7, n2) * moss_amount;
	color = mix(color, moss_color, moss_mask);
	
	// Scattered leaf litter
	float leaf_mask = smoothstep(0.6, 0.8, n3) * leaf_amount;
	color = mix(color, leaf_color, leaf_mask);
	
	// Micro detail for texture
	float detail = noise(uv * noise_scale * 4.0) * 0.1;
	color *= 0.95 + detail;
	
	ALBEDO = color;
	ROUGHNESS = roughness;
	METALLIC = 0.0;
}
