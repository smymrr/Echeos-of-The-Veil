shader_type canvas_item;

// Kecepatan gerak kabut (X = kanan/kiri, Y = atas/bawah)
// Dipercepat biar kelihatan gerak maju!
uniform vec2 speed = vec2(0.08 0.03);

// Warna & Ketebalan Kabut
// Alpha (A) dinaikkan ke 0.65 biar LEBIH TEBAL & PEKAT!
uniform vec4 fog_color : source_color = vec4(0.85, 0.88, 0.9, 0.65);

float rand(vec2 coord) {
	return fract(sin(dot(coord, vec2(56.782, 15.321))) * 43758.5453);
}

float noise(vec2 coord) {
	vec2 i = floor(coord);
	vec2 f = fract(coord);

	float a = rand(i);
	float b = rand(i + vec2(1.0, 0.0));
	float c = rand(i + vec2(0.0, 1.0));
	float d = rand(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 coord) {
	float value = 0.0;
	float scale = 0.5;

	for (int i = 0; i < 4; i++) {
		value += noise(coord) * scale;
		coord *= 2.0;
		scale *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 coord = UV * 3.5;
	vec2 motion = vec2(TIME * speed.x, TIME * speed.y);
	
	float n = fbm(coord + motion);
	
	// Peningkatan kontras biar kabutnya tebal dan menggumpal
	float dense_fog = smoothstep(0.15, 0.85, n);
	
	COLOR = vec4(fog_color.rgb, dense_fog * fog_color.a);
}