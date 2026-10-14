shader_type canvas_item;

// Sello encima de las fichas de sinergia bloqueadas en el códice: rayas
// diagonales que se deslizan despacio, un parpadeo leve y los bordes más
// oscuros. Va sobre un ColorRect que cubre la ficha.

uniform vec4 stripe_color : source_color = vec4(0.32, 0.85, 0.78, 1.0);
uniform float density = 22.0;
uniform float speed = 0.12;
uniform float strength = 0.07;
uniform float vignette = 0.45;

void fragment() {
	float d = (UV.x * 1.8 + UV.y) * density - TIME * speed * density;
	float stripe = step(0.55, fract(d));
	float flicker = 0.8 + 0.2 * sin(TIME * 6.0 + UV.y * 30.0);
	float a_stripe = stripe * strength * flicker;
	float a_vig = smoothstep(0.25, 0.75, distance(UV, vec2(0.5))) * vignette;
	float alpha = a_stripe + a_vig;
	vec3 col = stripe_color.rgb * (a_stripe / max(alpha, 0.001));
	COLOR = vec4(col, alpha);
}
