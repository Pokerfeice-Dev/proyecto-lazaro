shader_type canvas_item;
uniform vec2 center = vec2(0.5);
uniform float progress = 0.0;
uniform float aspect = 1.7778;
uniform sampler2D destination_screen : hint_screen_texture, repeat_disable, filter_linear;
void fragment() {
	vec2 p = (UV - center) * vec2(aspect, 1.0);
	float radius = progress * (aspect + 1.0);
	float d = length(p);
	float envelope = sin(progress * 3.14159);
	float band = exp(-pow((d - radius) / 0.075, 2.0)) * envelope;
	float rim = exp(-abs(d - radius) * 160.0) * envelope;
	vec2 direction = normalize(p + vec2(0.0001)) / vec2(aspect, 1.0);
	vec2 warp = direction * band * sin((d - radius) * 42.0) * 0.045;
	vec2 sample_uv = clamp(SCREEN_UV + warp, vec2(0.001), vec2(0.999));
	vec3 incoming = texture(destination_screen, sample_uv).rgb;
	incoming.r = texture(destination_screen, clamp(sample_uv + direction * band * 0.003, vec2(0.001), vec2(0.999))).r;
	incoming.b = texture(destination_screen, clamp(sample_uv - direction * band * 0.003, vec2(0.001), vec2(0.999))).b;
	vec3 old = texture(TEXTURE, clamp(UV + warp, vec2(0.0), vec2(1.0))).rgb;
	float outside = smoothstep(radius - 0.025, radius + 0.025, d);
	vec3 result = mix(incoming, old, outside);
	result += vec3(0.55, 0.85, 1.0) * rim * 0.7 + vec3(0.1, 0.22, 0.3) * band * 0.12;
	COLOR = vec4(result, 1.0);
}
