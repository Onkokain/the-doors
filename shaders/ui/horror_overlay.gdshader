shader_type canvas_item;
render_mode unshaded;

uniform vec4 base_tint : source_color = vec4(0.03, 0.0, 0.0, 0.8);
uniform vec4 haze_tint : source_color = vec4(0.58, 0.05, 0.08, 0.28);
uniform float haze_scale = 3.4;
uniform float haze_speed = 0.12;
uniform float scanline_strength = 0.05;
uniform float grain_strength = 0.035;
uniform float vignette_strength = 0.72;
uniform float edge_darkness = 0.4;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	vec2 uv = UV;
	float time = TIME * haze_speed;
	float haze_primary = noise(uv * haze_scale + vec2(time, -time * 0.8));
	float haze_secondary = noise(uv * haze_scale * 2.2 - vec2(time * 1.6, time));
	float haze = clamp(haze_primary * 0.7 + haze_secondary * 0.3, 0.0, 1.0);
	float scanline = sin((uv.y + TIME * 0.2) * 900.0) * 0.5 + 0.5;
	vec2 viewport_size = 1.0 / SCREEN_PIXEL_SIZE;
	float grain = hash(uv * viewport_size + vec2(fract(TIME) * 2400.0)) - 0.5;
	float vignette = smoothstep(0.38, 0.95, length((uv - 0.5) * vec2(1.3, 1.0)));
	vec3 color = base_tint.rgb;
	color += haze_tint.rgb * haze * haze_tint.a * (0.85 + 0.15 * sin(TIME * 0.7));
	color += vec3(scanline * scanline_strength);
	color += vec3(grain * grain_strength);
	color *= 1.0 - vignette * edge_darkness;
	float alpha = clamp(base_tint.a + haze * 0.18 + vignette * vignette_strength, 0.0, 1.0);
	COLOR = vec4(color, alpha);
}
