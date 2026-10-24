shader_type canvas_item;
render_mode unshaded;
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 uv = floor(UV * 160.0) / 160.0;
	vec2 p = (uv - 0.5) * 2.0;
	float d = length(p);
	float angle = atan(p.y, p.x);
	float wave = sin(d * 24.0 - TIME * 4.0 + sin(angle * 3.0 + TIME)) * 0.018;
	float twist = sin(TIME * 1.4 + d * 8.0) * 0.06 * d;
	mat2 rotation = mat2(vec2(cos(twist), sin(twist)), vec2(-sin(twist), cos(twist)));
	vec2 warped = clamp(0.5 + rotation * p * (0.5 + wave), vec2(0.01), vec2(0.99));
	vec3 c = texture(TEXTURE, warped).rgb;
	c.r = texture(TEXTURE, warped + p * 0.009).r;
	c.b = texture(TEXTURE, warped - p * 0.009).b;
	float rim = smoothstep(0.72, 0.96, d);
	float flow = 0.65 + 0.35 * sin(angle * 7.0 - TIME * 3.0 + d * 16.0);
	c = mix(c, mix(vec3(0.35, 0.12, 0.8), vec3(0.3, 1.0, 1.0), flow), rim * 0.85);
	c += vec3(0.25, 0.8, 1.0) * pow(rim, 3.0) * 0.4;
	COLOR = tint * vec4(c, 1.0 - smoothstep(0.96, 1.0, d));
}
