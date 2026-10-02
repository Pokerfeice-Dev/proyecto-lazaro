shader_type canvas_item;

// Fondo de la pantalla de opciones: desenfoca lo que hay atras (el menu sigue vivo, pero borroso),
// lo oscurece con un tinte frio y le suma lineas diagonales que se desplazan lento, scanlines y vineta.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float blur_px = 3.0;
uniform float oscuridad : hint_range(0.0, 1.0) = 0.6;
uniform vec4 tinte : source_color = vec4(0.02, 0.06, 0.08, 1.0);
uniform vec4 color_lineas : source_color = vec4(0.35, 1.0, 0.85, 1.0);
uniform float aparicion : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * blur_px;
	vec3 acc = vec3(0.0);
	float peso = 0.0;
	for (int x = -3; x <= 3; x++) {
		for (int y = -3; y <= 3; y++) {
			float k = exp(-float(x * x + y * y) / 8.0);
			acc += texture(screen_tex, SCREEN_UV + vec2(float(x), float(y)) * px).rgb * k;
			peso += k;
		}
	}
	vec3 col = mix(acc / peso, tinte.rgb, oscuridad);

	vec2 p = FRAGCOORD.xy;
	float diag = fract((p.x + p.y) / 64.0 - TIME * 0.06);
	float lineas = smoothstep(0.035, 0.0, abs(diag - 0.5)) * 0.07;
	float scan = 0.025 * sin(p.y * 1.6);
	vec2 c = SCREEN_UV - 0.5;
	float vineta = smoothstep(0.35, 0.85, length(c * vec2(1.0, 0.8)));
	col += color_lineas.rgb * lineas;
	col -= scan;
	col *= 1.0 - vineta * 0.55;

	COLOR = vec4(col, aparicion);
}
