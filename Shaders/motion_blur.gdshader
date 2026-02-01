shader_type canvas_item;

// Radial motion blur + edge warp for speed boost effect
uniform float blur_amount : hint_range(0.0, 1.0) = 0.0;
uniform float blur_strength : hint_range(0.0, 0.1) = 0.02;
uniform vec2 blur_center = vec2(0.5, 0.5);
uniform int samples : hint_range(4, 32) = 16;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.4;
uniform vec4 tint_color : source_color = vec4(0.2, 0.6, 1.0, 0.2);
uniform float warp_strength : hint_range(0.0, 0.2) = 0.08;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 center_offset = uv - blur_center;
	float dist = length(center_offset);
	
	// Edge warp - barrel distortion at edges
	float edge_factor = smoothstep(0.3, 0.8, dist);
	float warp = edge_factor * warp_strength * blur_amount;
	
	// Animated wave warp
	float wave = sin(dist * 20.0 - TIME * 6.0) * 0.3 + 0.7;
	vec2 warp_offset = normalize(center_offset + 0.001) * warp * wave;
	vec2 warped_uv = uv + warp_offset;
	
	// Radial blur on warped UVs
	vec4 color = vec4(0.0);
	float strength = blur_strength * blur_amount * dist;
	
	for (int i = 0; i < samples; i++) {
		float t = float(i) / float(samples - 1);
		vec2 offset = center_offset * strength * t;
		color += texture(SCREEN_TEXTURE, warped_uv - offset);
	}
	color /= float(samples);
	
	// Chromatic aberration at edges
	float chroma_strength = edge_factor * 0.008 * blur_amount;
	vec2 chroma_dir = normalize(center_offset + 0.001);
	color.r = texture(SCREEN_TEXTURE, warped_uv + chroma_dir * chroma_strength).r * 0.3 + color.r * 0.7;
	color.b = texture(SCREEN_TEXTURE, warped_uv - chroma_dir * chroma_strength).b * 0.3 + color.b * 0.7;
	
	// Edge darkening vignette
	float vignette = 1.0 - dist * vignette_strength * blur_amount;
	color.rgb *= vignette;
	
	// Blue tint
	color.rgb = mix(color.rgb, tint_color.rgb, tint_color.a * blur_amount);
	
	// Radial speed lines at edges
	float edge_lines = edge_factor * blur_amount;
	float lines = fract(dist * 25.0 - TIME * 10.0);
	lines = smoothstep(0.85, 1.0, lines);
	color.rgb += vec3(0.3, 0.7, 1.0) * lines * edge_lines * 0.5;
	
	COLOR = color;
}
