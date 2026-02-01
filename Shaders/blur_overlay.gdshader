shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.0;
uniform float darken : hint_range(0.0, 1.0) = 0.4;
uniform vec4 tint_color : source_color = vec4(0.05, 0.1, 0.08, 1.0);

void fragment() {
	vec2 pixel_size = 1.0 / vec2(textureSize(SCREEN_TEXTURE, 0));
	
	vec4 color = vec4(0.0);
	float total = 0.0;
	
	// Simple box blur
	for (float x = -4.0; x <= 4.0; x += 1.0) {
		for (float y = -4.0; y <= 4.0; y += 1.0) {
			vec2 offset = vec2(x, y) * pixel_size * blur_amount;
			color += texture(SCREEN_TEXTURE, SCREEN_UV + offset);
			total += 1.0;
		}
	}
	
	color /= total;
	
	// Darken and tint
	color.rgb *= (1.0 - darken);
	color.rgb = mix(color.rgb, tint_color.rgb, 0.3);
	
	COLOR = color;
}
