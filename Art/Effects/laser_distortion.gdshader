shader_type canvas_item;
render_mode unshaded;

// Shader de distorsión y aberración cromática/blur de calor alrededor del rayo.
// Usa hint_screen_texture para distorsionar la imagen del mundo en tiempo real.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.025;
uniform float chromatic_aberration : hint_range(0.0, 0.05) = 0.012;
uniform float blur_amount : hint_range(0.0, 5.0) = 1.5;
uniform float heat_speed : hint_range(0.0, 30.0) = 18.0;

void fragment() {
	// Gradiente de desvanecimiento hacia los bordes superior/inferior del haz local
	float edge_fade = sin(UV.y * 3.14159265);
	edge_fade = pow(edge_fade, 1.8);
	
	// Ondas sinusoidales superpuestas simulando calor extremo y turbulencia de aire
	float wave1 = sin(UV.x * 24.0 - TIME * heat_speed);
	float wave2 = cos(UV.x * 48.0 + TIME * (heat_speed * 1.3));
	float wave3 = sin((UV.x + UV.y) * 36.0 - TIME * (heat_speed * 0.7));
	float displacement = (wave1 * 0.5 + wave2 * 0.3 + wave3 * 0.2) * distortion_strength * edge_fade;
	
	vec2 offset = vec2(0.0, displacement);
	
	// Muestreo con separación cromática y leve blur en 4 direcciones
	vec2 uv_base = SCREEN_UV + offset;
	vec2 chroma_offset = vec2(displacement * chromatic_aberration * 10.0, 0.0);
	
	vec3 color_r = texture(screen_texture, clamp(uv_base + chroma_offset, vec2(0.001), vec2(0.999))).rgb;
	vec3 color_g = texture(screen_texture, clamp(uv_base, vec2(0.001), vec2(0.999))).rgb;
	vec3 color_b = texture(screen_texture, clamp(uv_base - chroma_offset, vec2(0.001), vec2(0.999))).rgb;
	
	// Muestreo extra para sensación de blur suave por refracción térmica
	vec2 blur_step = vec2(0.002, 0.002) * blur_amount * edge_fade;
	vec3 blurred = (
		texture(screen_texture, clamp(uv_base + vec2(blur_step.x, 0.0), vec2(0.001), vec2(0.999))).rgb +
		texture(screen_texture, clamp(uv_base - vec2(blur_step.x, 0.0), vec2(0.001), vec2(0.999))).rgb +
		texture(screen_texture, clamp(uv_base + vec2(0.0, blur_step.y), vec2(0.001), vec2(0.999))).rgb +
		texture(screen_texture, clamp(uv_base - vec2(0.0, blur_step.y), vec2(0.001), vec2(0.999))).rgb
	) * 0.25;
	
	vec3 final_color = mix(vec3(color_r.r, color_g.g, color_b.b), blurred, 0.45);
	
	// Tinte sutil anaranjado/eléctrico de ionización del aire
	vec3 heat_tint = vec3(1.0, 0.45, 0.15) * (abs(displacement) * 3.5);
	final_color += heat_tint * edge_fade;
	
	COLOR = vec4(final_color, COLOR.a * edge_fade);
}
