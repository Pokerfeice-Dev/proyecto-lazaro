shader_type canvas_item;

// Recorta el sprite por encima de una línea (en coordenadas locales del sprite)
// y pinta un filo brillante justo en el corte. Lo usa el Centinela Génesis
// para salir de la pared: el sprite baja y el corte se corre con él.
uniform float cutoff = -10000.0;
uniform vec4 edge_color : source_color = vec4(1.0, 0.35, 0.25, 1.0);
uniform float edge_width = 2.0;
// 0 = color normal, 1 = silueta negra (se aclara mientras sale).
uniform float shade = 0.0;

varying float local_y;

void vertex() {
	local_y = VERTEX.y;
}

void fragment() {
	if (local_y < cutoff) {
		discard;
	}
	COLOR.rgb *= 1.0 - shade;
	float k = 1.0 - clamp((local_y - cutoff) / edge_width, 0.0, 1.0);
	COLOR.rgb = mix(COLOR.rgb, edge_color.rgb, k * 0.85);
}
