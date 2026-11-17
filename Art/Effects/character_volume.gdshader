shader_type canvas_item;
// Volumen para personajes (jugador, enemigos y NPCs). Lo aplica CharacterLook y se apaga con
// Opciones > Efectos > "Volumen en personajes". Pensado para pixel art: no suaviza ni agrega
// píxeles, solo aclara u oscurece los que ya están.
//  - Borde de luz: el píxel del contorno que da hacia arriba-izquierda se aclara un poco
//    (como el brillo que el arte del juego ya pinta a mano, pero también en las partes nuevas).
//  - Sombra de suelo: los pies quedan un poco más oscuros que la cabeza.
//  - Cerca de una lámpara (PointLight2D), el lado del cuerpo que mira a la luz se aclara y el
//    otro se oscurece. El "bisel" sale del contorno del propio sprite: no hacen falta mapas de
//    normales. Sin luces cerca, este paso no corre (lo hace el motor solo por cada luz).
// Costo: 3 lecturas de textura por píxel en el sprite + 4 por luz que lo toca.

uniform float rim_strength : hint_range(0.0, 1.0) = 0.35;
uniform vec4 rim_color : source_color = vec4(1.0, 0.94, 0.82, 1.0);
uniform float foot_shade : hint_range(0.0, 0.6) = 0.12;
// Píxeles (desde el centro del sprite hacia abajo) donde empieza y termina la sombra de suelo.
uniform vec2 foot_range = vec2(6.0, 18.0);
// Cuánto se aclara el borde que mira a la lámpara y cuánto se oscurece el del otro lado
// (menos, para que el personaje no quede más oscuro que antes en general).
uniform float bevel_strength : hint_range(0.0, 1.5) = 0.75;
uniform float bevel_shadow : hint_range(0.0, 1.0) = 0.3;
uniform float bevel_radius : hint_range(1.0, 4.0) = 2.0;

varying vec2 v_local;
varying vec2 v_edge;

void vertex() {
	v_local = VERTEX;
}

float alpha_at(sampler2D tex, vec2 uv) {
	return texture(tex, uv).a;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 c = tex * COLOR;
	v_edge = vec2(0.0);
	if (tex.a > 0.5) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		// el sprite puede estar volteado: el signo de la derivada dice hacia dónde avanza la UV
		vec2 dir = vec2(sign(dFdx(UV.x)), sign(dFdy(UV.y)));
		dir = mix(vec2(1.0), dir, step(0.0001, abs(dir)));
		float open_up = 1.0 - alpha_at(TEXTURE, UV - vec2(0.0, px.y * dir.y));
		float open_left = 1.0 - alpha_at(TEXTURE, UV - vec2(px.x * dir.x, 0.0));
		float rim = clamp(open_up + open_left * 0.5, 0.0, 1.0);
		c.rgb = mix(c.rgb, c.rgb * 0.55 + rim_color.rgb * 0.55, rim * rim_strength);
		float foot = smoothstep(foot_range.x, foot_range.y, v_local.y);
		c.rgb *= 1.0 - foot_shade * foot;
		// normal del borde en pantalla (hacia afuera del cuerpo), para la luz: izquierda menos
		// derecha da -1 en el borde izquierdo, que es justo la dirección hacia afuera
		vec2 rx = vec2(px.x * bevel_radius * dir.x, 0.0);
		vec2 ry = vec2(0.0, px.y * bevel_radius * dir.y);
		float ax = alpha_at(TEXTURE, UV - rx) - alpha_at(TEXTURE, UV + rx);
		float ay = alpha_at(TEXTURE, UV - ry) - alpha_at(TEXTURE, UV + ry);
		v_edge = vec2(ax, ay);
	}
	COLOR = c;
}

void light() {
	float k = 1.0;
	vec2 to_light = LIGHT_DIRECTION.xy;
	float len = length(to_light);
	if (len > 0.001) {
		// v_edge apunta hacia afuera: si mira a la luz, ese borde se aclara; si no, se oscurece
		float facing = clamp(dot(v_edge, to_light / len), -1.0, 1.0);
		k = 1.0 + bevel_strength * max(facing, 0.0) - bevel_shadow * max(-facing, 0.0);
	}
	LIGHT = vec4(LIGHT_COLOR.rgb * COLOR.rgb * LIGHT_ENERGY * k, LIGHT_COLOR.a);
}
