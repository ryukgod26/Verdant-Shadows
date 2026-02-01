shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;

uniform vec3 base_color : source_color = vec3(0.12, 0.35, 0.08);
uniform vec3 tip_color : source_color = vec3(0.2, 0.5, 0.15);
uniform float wind_strength : hint_range(0.0, 0.5) = 0.1;
uniform float wind_speed : hint_range(0.0, 5.0) = 1.5;
uniform float color_variation : hint_range(0.0, 1.0) = 0.3;

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

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Wind sway - more movement at top of bush
	float height_factor = max(0.0, VERTEX.y) * 2.0;
	float wind_time = TIME * wind_speed;
	
	float wind_x = sin(wind_time + world_pos.x * 0.5 + world_pos.z * 0.3) * wind_strength;
	float wind_z = cos(wind_time * 0.8 + world_pos.z * 0.4) * wind_strength * 0.6;
	
	// Add some variation based on position
	wind_x += sin(wind_time * 1.3 + world_pos.x) * wind_strength * 0.3;
	
	VERTEX.x += wind_x * height_factor;
	VERTEX.z += wind_z * height_factor;
}

void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Gradient from base to tip
	float height_blend = smoothstep(-0.2, 0.4, VERTEX.y);
	vec3 color = mix(base_color, tip_color, height_blend);
	
	// Add noise-based color variation
	float n = noise(world_pos.xz * 3.0);
	color = mix(color, color * (0.8 + n * 0.4), color_variation);
	
	// Subtle darker patches for depth
	float dark_patch = noise(world_pos.xz * 1.5 + 50.0);
	color *= 0.9 + dark_patch * 0.2;
	
	ALBEDO = color;
	ROUGHNESS = 0.9;
}
