shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec4 fog_color : source_color = vec4(0.85, 0.9, 0.95, 1.0);
uniform float density : hint_range(0.0, 1.0) = 0.35;
uniform float noise_scale = 0.0015;            // smaller = bigger clouds
uniform vec2 scroll_a = vec2(0.010, 0.004);
uniform vec2 scroll_b = vec2(-0.006, 0.003);
uniform float pixel_size = 4.0;                // chunky pixels to match your art; 1.0 = smooth
uniform vec2 view_size = vec2(640.0, 360.0);   // set by the script
uniform vec2 world_offset = vec2(0.0);         // set by the script (top-left of the view, in world units)

void fragment() {
	vec2 world_pos = UV * view_size + world_offset;
	world_pos = floor(world_pos / pixel_size) * pixel_size;

	// Two layers of noise drifting in different directions look much less repetitive than one
	float n1 = texture(noise_tex, world_pos * noise_scale + TIME * scroll_a).r;
	float n2 = texture(noise_tex, world_pos * noise_scale * 1.7 + TIME * scroll_b).r;
	float n = (n1 + n2) * 0.5;

	float fog = smoothstep(0.35, 0.85, n) * density;
	COLOR = vec4(fog_color.rgb, fog);
}