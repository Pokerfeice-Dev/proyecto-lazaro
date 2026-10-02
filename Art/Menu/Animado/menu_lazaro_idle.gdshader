shader_type canvas_item;

// Idle del fondo del menu: Lazaro respira, mueve la cabeza y los hombros y el pelo se balancea.
// Las manos quedan quietas (estan agarrando los barrotes) y los barrotes van en otra capa encima.
// Las zonas que se mueven salen de dos mascaras pintadas sobre el artwork (905x720).

uniform sampler2D mascara_cuerpo : filter_linear, hint_default_black; // R cabeza, G hombros/brazos, B torso
uniform sampler2D mascara_extra : filter_linear, hint_default_black;  // R fondo, G pelo
uniform sampler2D niebla : repeat_enable, filter_linear;               // ruido sin costuras para la niebla
uniform vec2 tam_px = vec2(905.0, 720.0);

uniform float intensidad : hint_range(0.0, 2.0) = 1.0;    // multiplica todo el movimiento del cuerpo
uniform float respiracion_seg = 4.6;                     // duracion de una respiracion completa
uniform float respiracion_fuerza : hint_range(0.0, 4.0) = 2.2; // que tan marcada es la respiracion
uniform float giro_cabeza_grados = 1.1;
uniform float niebla_fuerza : hint_range(0.0, 1.0) = 0.22;
uniform float luz_pulso : hint_range(0.0, 0.3) = 0.05;
uniform vec3 niebla_color : source_color = vec3(0.55, 0.62, 0.85);

const vec2 PIVOTE_TORSO = vec2(445.0, 480.0);  // cinturon: el pecho se expande desde aca
const vec2 PIVOTE_CUELLO = vec2(445.0, 225.0);
const vec2 CENTRO_LUZ = vec2(0.0, 60.0);       // la luz de arriba a la izquierda

vec2 desplazamiento(vec2 p, float t) {
	vec3 m = texture(mascara_cuerpo, p / tam_px).rgb;
	float pelo = texture(mascara_extra, p / tam_px).g;
	float resp = sin(t * TAU / respiracion_seg) * respiracion_fuerza;

	vec2 d = vec2(0.0);
	d += m.b * (p - PIVOTE_TORSO) * vec2(0.004, 0.008) * resp;   // pecho que respira
	d += m.g * vec2(0.0, -1.6) * resp;                          // hombros suben al inhalar

	float ang = radians(giro_cabeza_grados) * sin(t * 0.37 + 0.8);
	vec2 rel = p - PIVOTE_CUELLO;
	vec2 rot = vec2(rel.x * cos(ang) - rel.y * sin(ang), rel.x * sin(ang) + rel.y * cos(ang));
	d += m.r * ((rot - rel) + vec2(0.6 * sin(t * 0.23), -1.2 * resp));  // cabeza

	d += pelo * vec2(1.4 * sin(t * 0.9 + p.y * 0.02), 0.0);         // mechones que se balancean
	return d * intensidad;
}

void fragment() {
	float t = TIME;
	vec2 p = UV * tam_px;
	vec2 uv = (p - desplazamiento(p, t)) / tam_px;
	vec4 col = texture(TEXTURE, uv);

	float fondo = texture(mascara_extra, UV).r;
	float luz = smoothstep(420.0, 0.0, length(p - CENTRO_LUZ));
	float pulso = luz_pulso * sin(t * 0.8) + luz_pulso * 0.5 * sin(t * 2.3 + 1.0);
	col.rgb *= 1.0 + luz * pulso * fondo;

	vec2 uv_n1 = UV * vec2(1.6, 1.3) + vec2(t * 0.012, -t * 0.004);
	vec2 uv_n2 = UV * 0.8 - vec2(t * 0.007, 0.0);
	float n = texture(niebla, uv_n1).r * texture(niebla, uv_n2).r;
	col.rgb += niebla_color * n * niebla_fuerza * fondo;

	COLOR = col;
}
