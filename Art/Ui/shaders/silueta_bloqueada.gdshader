shader_type canvas_item;

// Silueta de algo que todavía no se desbloqueó (sinergias y armas en O.M.N.I.A.):
// el sprite queda en sombra y un poco borroso, con un borde turquesa que late
// y una línea de escaneo que lo recorre de arriba abajo.

uniform vec4 shadow_color : source_color = vec4(0.02, 0.07, 0.09, 1.0);
uniform vec4 glow_color : source_color = vec4(0.32, 0.85, 0.78, 1.0);
uniform float blur = 1.0;
uniform float scan_speed = 0.4;
// Desfase para que cada ícono no lata al mismo tiempo que los demás.
uniform float phase = 0.0;
// 0 = silueta, 1 = sprite normal. Se anima al desbloquear (con un destello en el medio).
uniform float reveal : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	vec2 px = TEXTURE_PIXEL_SIZE * blur;
	float own = texture(TEXTURE, UV).a;
	float right = texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
	float left = texture(TEXTURE, UV - vec2(px.x, 0.0)).a;
	float down = texture(TEXTURE, UV + vec2(0.0, px.y)).a;
	float up = texture(TEXTURE, UV - vec2(0.0, px.y)).a;

	float soft = own * 0.4 + (right + left + down + up) * 0.15;
	float rim = clamp(max(max(right, left), max(down, up)) - own, 0.0, 1.0);

	float pulse = 0.55 + 0.45 * sin(TIME * 2.2 + phase * 6.2831);
	float scan_pos = fract(TIME * scan_speed + phase);
	float scan = smoothstep(0.07, 0.0, abs(UV.y - scan_pos));

	vec3 col = shadow_color.rgb + glow_color.rgb * scan * 0.45 * soft;
	col = mix(col, glow_color.rgb, rim * pulse * 0.8);
	vec4 locked = vec4(col, max(soft * 0.92, rim * pulse * 0.7));
	vec4 shown = mix(locked, base, reveal);
	float flash = reveal * (1.0 - reveal) * 4.0;
	shown.rgb += glow_color.rgb * flash * base.a;
	COLOR = shown;
}
