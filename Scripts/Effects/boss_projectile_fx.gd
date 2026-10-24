extends Node2D
## Cometa pixelado local: una sola geometría animada por bala, sin luces extra.
var age := 0.0
var impact_age := -1.0
var enhanced := false
var flight_speed := 300.0

func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat
	z_index = 5

func impact() -> void:
	if impact_age < 0.0: impact_age = 0.0

func _process(delta: float) -> void:
	age += delta
	if impact_age >= 0.0: impact_age += delta
	queue_redraw()

func _draw() -> void:
	var hot := Color("ff7138").lerp(Color("ec51ff"), 0.5 + 0.5 * sin(age * 7))
	var cool := Color("69dfff")
	if enhanced: hot = hot.lerp(Color("bd65ff"), 0.45)
	if impact_age >= 0.0:
		var progress := clampf(impact_age / 0.36, 0, 1)
		var alpha := 1.0 - progress
		draw_arc(Vector2.ZERO, 3 + progress * 24, 0, TAU, 12, Color(hot, alpha), 2)
		for i in 8:
			var dir := Vector2.from_angle(float(i) * TAU / 8 + 0.2)
			var point := (dir * (5 + progress * 30)).round()
			draw_line(point, (point - dir * 6 * alpha).round(), Color(cool if i % 2 == 0 else hot, alpha), 2)
		draw_rect(Rect2(Vector2(-4, -4) * alpha, Vector2(8, 8) * alpha), Color(1, 1, 0.9, alpha))
		return
	var tail_length := minf(58.0 if enhanced else 48.0, age * flight_speed)
	# La cola se estrecha y desvanece detrás del núcleo peligroso.
	var count := 8 if OS.has_feature("web") else 12
	for i in range(count, 0, -1):
		var t := float(i) / count
		var point := Vector2(-tail_length * t, sin(age * 24 - t * 9) * 3.5 * t).round()
		var width := (1 - t) * 7 + 1
		var tint := hot.lerp(cool, t)
		draw_rect(Rect2(point - Vector2(3, width), Vector2(tail_length / count + 3, width * 2)), Color(tint, (1 - t) * 0.65))
		draw_rect(Rect2(point - Vector2(2, width * 0.35), Vector2(5, maxf(1, width * 0.7))), Color(tint.lightened(0.35), (1 - t) * 0.9))
	# Motas expulsadas hacia atrás; cantidad fija, sin crear nodos.
	for i in 5:
		var phase := fposmod(age * 2.5 + i * 0.21, 1.0)
		var sign_side := 1.0 if i % 2 == 0 else -1.0
		var pos := Vector2(-tail_length * phase, sign_side * (3 + phase * 11)).round()
		draw_rect(Rect2(pos, Vector2(2, 2)), Color(cool if i % 2 == 0 else hot, (1 - phase) * minf(age * 8, 1)))
	var pulse := 1.0 + sin(age * 22) * 0.12
	draw_circle(Vector2.ZERO, 10 * pulse, Color(hot, 0.15))
	draw_colored_polygon(PackedVector2Array([Vector2(8, 0), Vector2(0, -6), Vector2(-7, 0), Vector2(0, 6)]), hot)
	draw_rect(Rect2(-3, -3, 6, 6), Color("fff7d9"))
	draw_line(Vector2(-1, -8) * pulse, Vector2(-1, 8) * pulse, Color(cool, 0.65), 1)
