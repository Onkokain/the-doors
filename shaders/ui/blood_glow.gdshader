shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 glow_color : source_color = vec4(0.75, 0.05, 0.08, 0.32);
uniform vec2 stretch = vec2(1.25, 0.78);
uniform float intensity = 1.0;
uniform float pulse_speed = 1.0;
uniform float wobble_amount = 0.035;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	uv.x *= stretch.x;
	uv.y *= stretch.y;
	uv += vec2(
		sin(TIME * pulse_speed * 0.8),
		cos(TIME * pulse_speed * 0.65)
	) * wobble_amount;
	float glow = smoothstep(1.2, 0.0, length(uv));
	glow = pow(glow, 2.1);
	glow *= 0.86 + 0.14 * sin(TIME * pulse_speed);
	COLOR = vec4(glow_color.rgb, glow * glow_color.a * intensity);
}
