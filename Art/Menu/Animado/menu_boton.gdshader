shader_type canvas_item;

// FX de los botones del menu principal: brillo que cruza en diagonal cada tanto,
// borde electrico que titila con el hover y destello blanco al hacer click.
// "hover" y "flash" los anima main_menu.gd con tweens.

uniform float hover : hint_range(0.0, 1.0) = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec2 tam_px = vec2(300.0, 80.0);
uniform vec4 color_borde : source_color = vec4(0.35, 1.0, 0.85, 1.0);
uniform float periodo_brillo = 4.0;
uniform float desfase_brillo = 0.0;   // cada boton con su desfase, asi el brillo baja en cascada

varying vec2 local;

void vertex() {
	local = VERTEX;
}

float ruido(float x) {
	return fract(sin(x * 127.1) * 43758.5453);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	vec2 q = local / tam_px;

	// brillo diagonal (mas fuerte con el hover)
	float fase = fract(TIME / periodo_brillo + desfase_brillo) * 2.6 - 0.8;
	float x = q.x + q.y * 0.35;
	float brillo = smoothstep(0.10, 0.0, abs(x - fase));
	c.rgb += vec3(0.9, 1.0, 1.0) * brillo * (0.12 + 0.28 * hover) * c.a;

	// borde electrico: titila rapido con saltos al azar, solo con el hover
	float d = min(min(local.x, tam_px.x - local.x), min(local.y, tam_px.y - local.y));
	float titileo = 0.65 + 0.35 * sin(TIME * 23.0) * ruido(floor(TIME * 18.0));
	float borde = smoothstep(7.0, 0.0, d) * hover * titileo;
	c.rgb += color_borde.rgb * borde * 0.9 * c.a;

	// leve tinte cian en todo el boton con el hover
	c.rgb = mix(c.rgb, c.rgb * vec3(0.85, 1.15, 1.12), hover * 0.5);

	// destello al hacer click
	c.rgb = mix(c.rgb, vec3(1.0), flash * 0.7 * c.a);
	COLOR = c;
}
