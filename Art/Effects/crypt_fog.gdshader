shader_type canvas_item;
render_mode unshaded;

// Una sola pasada liviana: la niebla se limita al tercio inferior y se mueve
// lentamente para no competir con proyectiles, telegráficos ni el pixel art.
uniform vec4 fog_color : source_color = vec4(0.38, 0.48, 0.62, 1.0);
uniform float density : hint_range(0.0, 0.12, 0.005) = 0.042;
uniform float drift_speed : hint_range(0.0, 0.08, 0.001) = 0.012;
uniform float scale : hint_range(1.0, 10.0, 0.1) = 4.0;

float hash(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 local = fract(point);
	local = local * local * (3.0 - 2.0 * local);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), local.x), mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), local.x), local.y);
}

float fog_noise(vec2 point) {
	return noise(point) * 0.58 + noise(point * 2.07 + 19.0) * 0.29 + noise(point * 4.11 + 41.0) * 0.13;
}

void fragment() {
	vec2 drift = vec2(TIME * drift_speed, -TIME * drift_speed * 0.16);
	float clouds = fog_noise(UV * scale + drift);
	float low_band = smoothstep(0.18, 0.82, UV.y);
	float alpha = smoothstep(0.42, 0.7, clouds) * low_band * density;
	COLOR = vec4(fog_color.rgb, alpha);
}
