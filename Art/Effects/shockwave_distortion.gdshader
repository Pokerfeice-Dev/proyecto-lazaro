shader_type canvas_item;
render_mode unshaded;

// Shader de distorsión radial por pulso de energía / shockwave
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float strength : hint_range(0.0, 0.15) = 0.04;
uniform float chromatic_aberration : hint_range(0.0, 0.08) = 0.02;

void fragment() {
	vec2 center = vec2(0.5);
	vec2 diff = UV - center;
	float dist = length(diff);
	
	// Anillo de distorsión convexa
	float ring = sin(clamp(dist * 3.14159265, 0.0, 3.14159265));
	ring = pow(ring, 2.0) * (1.0 - smoothstep(0.42, 0.5, dist));
	
	vec2 dir = normalize(diff + vec2(0.0001));
	vec2 offset = dir * ring * strength * 200.0 * SCREEN_PIXEL_SIZE * COLOR.a;
	
	vec2 uv = SCREEN_UV - offset;
	vec2 chroma = dir * chromatic_aberration * 100.0 * SCREEN_PIXEL_SIZE * ring * COLOR.a;
	
	float r = texture(screen_texture, clamp(uv + chroma, vec2(0.001), vec2(0.999))).r;
	float g = texture(screen_texture, clamp(uv, vec2(0.001), vec2(0.999))).g;
	float b = texture(screen_texture, clamp(uv - chroma, vec2(0.001), vec2(0.999))).b;
	
	// Un toque sutil de resplandor eléctrico azul/amarillo en el borde de choque
	vec3 tint = vec3(0.7, 0.85, 1.2) * (ring * COLOR.a * 0.4);
	
	COLOR = vec4(vec3(r, g, b) + tint, COLOR.a * ring);
}
