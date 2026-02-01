shader_type canvas_item;

uniform vec4 bg_color : source_color = vec4(0.04, 0.09, 0.06, 1.0);
uniform vec4 diamond_color : source_color = vec4(0.12, 0.25, 0.16, 1.0);
uniform float diamond_size : hint_range(20.0, 150.0) = 60.0;
uniform float line_thickness : hint_range(1.0, 8.0) = 2.5;

void fragment() {
	vec2 pixel_pos = FRAGCOORD.xy;
	
	// Create diamond grid pattern
	float spacing = diamond_size;
	vec2 grid = mod(pixel_pos, spacing);
	
	// Diamond shape using manhattan distance
	vec2 center = vec2(spacing * 0.5);
	float dist = abs(grid.x - center.x) + abs(grid.y - center.y);
	
	// Create diamond outline
	float diamond_edge = spacing * 0.4;
	float edge = smoothstep(diamond_edge - line_thickness, diamond_edge, dist) - 
	             smoothstep(diamond_edge, diamond_edge + line_thickness, dist);
	
	// Mix colors
	vec4 final_color = mix(bg_color, diamond_color, edge * 0.8);
	
	// Add subtle inner fill
	float inner_fill = 1.0 - smoothstep(0.0, diamond_edge * 0.7, dist);
	final_color = mix(final_color, diamond_color, inner_fill * 0.2);
	
	COLOR = final_color;
}
