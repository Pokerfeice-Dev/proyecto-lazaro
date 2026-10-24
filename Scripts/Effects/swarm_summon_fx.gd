extends Node2D
## Ritual de colmena: geometría pixelada y motas de cantidad fija.
var age := 0.0
var duration := 1.0
var released := false
var birth := false

func _ready() -> void:
	z_index = 2
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat

func release() -> void:
	released = true
	age = 0.0

func _process(delta: float) -> void:
	if get_parent().get("is_dying") == true:
		queue_free()
		return
	age += delta
	if released and age > 0.65:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var center := Vector2(0, -8)
	var gold := Color("ffd25c")
	var green := Color("93ff86")
	var purple := Color("dc79ff")
	if released:
		var t := clampf(age / 0.65, 0, 1)
		var fade := 1 - t
		var radius := (9 + t * 45) * (0.65 if birth else 1.0)
		_hexagon(center, radius, Color(gold, fade), 2)
		draw_arc(center, radius * 0.75, -age * 6, TAU - age * 6, 18, Color(green, fade * 0.7), 2)
		var count := 12 if OS.has_feature("web") else 20
		for i in count:
			var direction := Vector2.from_angle(float(i) * TAU / count + sin(i * 5.7) * 0.25)
			var point := center + direction * radius * (0.7 + fposmod(i * 0.37, 0.8))
			point.y += t * t * 18
			var tint := gold if i % 2 == 0 else green
			draw_line(point.round(), (point - direction * 8 * fade).round(), Color(tint, fade * 0.6), 2)
			draw_rect(Rect2(point.round(), Vector2.ONE * (2 + i % 2)), Color(tint, fade))
		var flash := maxf(0, 1 - age / 0.14)
		draw_circle(center, 15, Color(gold, flash * 0.3))
		draw_line(center - Vector2(18, 0) * flash, center + Vector2(18, 0) * flash, Color(1, 1, 0.8, flash), 3)
		return
	var progress := clampf(age / maxf(duration, 0.01), 0, 1)
	var pulse := 0.5 + sin(age * 19) * 0.5
	# Sello hexagonal bajo la invocadora y anillos que convergen.
	var radius := 30 + pulse * 2
	_hexagon(Vector2(0, 9), radius, Color(gold, 0.35 + progress * 0.5), 2)
	for ring in 2:
		var phase := fposmod(age * 1.5 + ring * 0.5, 1)
		draw_arc(center, 12 + (1 - phase) * 26, age * 3 + ring * PI, age * 3 + ring * PI + PI * 1.3, 12, Color(green if ring == 0 else purple, phase * 0.7), 1)
	for i in 12:
		var phase := fposmod(age * 1.3 + i * 0.0833, 1)
		var angle := float(i) * TAU / 12 + age * 2
		var point := center + Vector2.from_angle(angle) * (8 + (1 - phase) * 35)
		point.y -= sin(phase * PI) * 12
		draw_rect(Rect2(point.round(), Vector2(2, 3)), Color(gold if i % 2 == 0 else green, phase))
	# Tres siluetas de insectos orbitan y baten las alas antes de liberarse.
	for i in 3:
		var angle := age * 4 + float(i) * TAU / 3
		var point := (center + Vector2(cos(angle) * 24, sin(angle) * 13)).round()
		var wing := 3 + absf(sin(age * 48 + i)) * 4
		draw_line(point - Vector2(wing, 3), point + Vector2(wing, -3), Color(green, 0.65), 2)
		draw_rect(Rect2(point - Vector2(2, 2), Vector2(4, 4)), gold)

func _hexagon(center: Vector2, radius: float, tint: Color, width: float) -> void:
	var points := PackedVector2Array()
	for i in 7:
		points.append((center + Vector2.from_angle(float(i) * TAU / 6) * radius * Vector2(1, 0.65)).round())
	draw_polyline(points, tint, width)
