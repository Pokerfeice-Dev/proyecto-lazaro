extends Control

## Capas suaves de laboratorio: motas, circuitos y monitor cardíaco.
var clock_time := 0.0
var energy := 0.0
var motes: Array[Vector3] = []
var motion_enabled := true
var particles_enabled := true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 44:
		motes.append(Vector3(randf(), randf(), randf_range(0.4, 1.0)))

func surge() -> void:
	energy = 1.0

func _process(delta: float) -> void:
	if motion_enabled:
		clock_time += delta
	energy = move_toward(energy, 0.0, delta * 1.8)
	queue_redraw()

func _draw() -> void:
	var teal := Color(0.25, 0.95, 0.78)
	if particles_enabled:
		for mote in motes:
			var p := Vector2(fposmod(mote.x + sin(clock_time * 0.25 + mote.y * 20.0) * 0.012, 1.0), fposmod(mote.y - clock_time * 0.013 * mote.z, 1.0)) * size
			var alpha := (0.18 + 0.17 * sin(clock_time * 1.6 + mote.x * 40.0)) * mote.z
			draw_circle(p, 6.0 * mote.z, Color(teal, alpha * 0.12))
			draw_rect(Rect2(p, Vector2.ONE * (1.0 + mote.z * 2.0)), Color(teal, alpha))
	# Circuitos en los márgenes, lejos de los botones y del logo.
	for side in [0.0, 1.0]:
		var x := lerpf(24.0, size.x - 24.0, side)
		var inward := 1.0 if side == 0.0 else -1.0
		var points := PackedVector2Array([Vector2(x, size.y * 0.2), Vector2(x, size.y * 0.7), Vector2(x + inward * 25.0, size.y * 0.7 + 25.0), Vector2(x + inward * 25.0, size.y * 0.9)])
		draw_polyline(points, Color(teal, 0.10 + energy * 0.2), 1.0, true)
		var pulse_y := lerpf(size.y * 0.2, size.y * 0.68, fposmod(clock_time * 0.13 + side * 0.5, 1.0))
		draw_circle(Vector2(x, pulse_y), 3.0, Color(teal, 0.55))
	var trace := PackedVector2Array()
	var origin := Vector2(50.0, size.y - 40.0)
	for i in 160:
		var phase := fposmod(float(i) / 160.0 - clock_time * 0.23, 1.0)
		var beat := -exp(-pow((phase - 0.50) * 60.0, 2.0)) * 18.0 + exp(-pow((phase - 0.55) * 65.0, 2.0)) * 10.0
		trace.append(origin + Vector2(float(i) * 1.4, beat))
	draw_polyline(trace, Color(teal, 0.38), 1.5, true)
	if motion_enabled:
		var scan_y := fposmod(clock_time * 45.0, size.y + 100.0) - 50.0
		draw_rect(Rect2(0, scan_y, size.x, 35), Color(teal, 0.015))
