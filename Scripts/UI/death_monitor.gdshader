shader_type canvas_item;
uniform vec2 focus = vec2(0.5);
uniform float darkness = 0.0;
uniform float pulse = 0.0;
uniform float clock = 0.0;
uniform float shutdown = 0.0;
void fragment() {
 vec2 ratio = vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
 float distance_to_body = length((SCREEN_UV - focus) * ratio);
 float mask = smoothstep(0.07, 0.30, distance_to_body);
 float edge = smoothstep(0.25, 0.68, length(UV - vec2(0.5)));
 float scan = sin(UV.y * 900.0 + clock * 50.0) * 0.012;
 vec3 tint = vec3(0.012, 0.018, 0.022) + vec3(0.65, 0.015, 0.035) * pulse * edge;
 float alpha = darkness * mix(0.28, 1.0, mask) + pulse * edge * 0.55 + scan;
 if (shutdown > 0.0) {
  float aperture = pow(1.0 - shutdown, 4.0) * 0.5;
  float outside = step(aperture, abs(UV.y - 0.5));
  tint = mix(tint, vec3(0.0), outside);
  alpha = mix(alpha, 1.0, outside);
  float line = (1.0 - smoothstep(0.0, 0.004, abs(UV.y - 0.5))) * (1.0 - shutdown);
  tint += vec3(0.32, 0.85, 0.78) * line;
  alpha = max(alpha, line);
 }
 COLOR = vec4(tint, clamp(alpha, 0.0, 1.0));
}
