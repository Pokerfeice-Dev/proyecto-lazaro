extends Node2D
var power := 0.0
var cutting := false
var contact := false
var clock := 0.0
var bursts: Array[Dictionary] = []
var _exhaust: CPUParticles2D

func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat
	z_index = 3
	_exhaust = CPUParticles2D.new()
	_exhaust.name = "MotorSmoke"
	_exhaust.emitting = false
	_exhaust.position = Vector2(-5, -7)
	_exhaust.z_index = -1
	_exhaust.local_coords = false
	_exhaust.amount = 12 if OS.has_feature("web") else 22
	_exhaust.lifetime = 0.65
	_exhaust.direction = Vector2.LEFT
	_exhaust.spread = 28
	_exhaust.gravity = Vector2(0, -28)
	_exhaust.initial_velocity_min = 20
	_exhaust.initial_velocity_max = 48
	_exhaust.damping_min = 12
	_exhaust.damping_max = 20
	_exhaust.scale_amount_min = 3
	_exhaust.scale_amount_max = 6
	var size_curve := Curve.new()
	size_curve.add_point(Vector2(0, 0.45))
	size_curve.add_point(Vector2(0.6, 1.0))
	size_curve.add_point(Vector2(1, 0.7))
	_exhaust.scale_amount_curve = size_curve
	var smoke_color := Gradient.new()
	smoke_color.set_color(0, Color(0.16, 0.13, 0.12, 0.75))
	smoke_color.add_point(0.25, Color(0.39, 0.36, 0.33, 0.6))
	smoke_color.add_point(0.65, Color(0.6, 0.57, 0.52, 0.3))
	smoke_color.set_color(1, Color(0.65, 0.62, 0.58, 0))
	_exhaust.color_ramp = smoke_color
	_exhaust.use_parent_material = true
	add_child(_exhaust)

func hit(point: Vector2, strong: bool) -> void:
	if bursts.size() >= 8: bursts.pop_front()
	bursts.append({"point": to_global(point), "age": 0.0, "strong": strong})

func _process(delta: float) -> void:
	clock += delta
	_exhaust.emitting = power > 0.08
	# Coordenadas globales: el humo queda atrás mientras el jugador avanza.
	_exhaust.initial_velocity_min = 12 + power * 20
	_exhaust.initial_velocity_max = 28 + power * (45 if contact else 25)
	for i in range(bursts.size() - 1, -1, -1):
		bursts[i].age += delta
		if bursts[i].age > 0.34: bursts.remove_at(i)
	queue_redraw()

func _draw() -> void:
	if power > 0.01:
		var hot := Color("ff742e").lerp(Color("fff1a1"), power)
		# Escape hacia atrás: llama dentada, humo y motas pixeladas.
		var length := maxf(5, (36 if cutting else 14) * power)
		var tail := PackedVector2Array([Vector2(-2, -8), Vector2(-length * 0.6, -10), Vector2(-length, -4), Vector2(-length * 0.55, 2), Vector2(-2, 0)])
		draw_colored_polygon(tail, Color(1, 0.28, 0.05, power * 0.6))
		draw_line(Vector2(-3, -4), Vector2(-length * (0.65 + sin(clock * 50) * 0.15), -4), hot, 3)
		for i in 9:
			var t := fposmod(clock * 3 + i / 9.0, 1)
			var point := Vector2(-6 - t * 65 * power, -4 + sin(i * 4.3) * t * 17)
			var tint := Color(0.32, 0.29, 0.35, (1 - t) * power * 0.4) if i % 3 == 0 else Color(hot, (1 - t) * power)
			draw_rect(Rect2(point.round(), Vector2.ONE * (5 if i % 3 == 0 else 2)), tint)
		# Pequeños destellos de dientes, sin arco de cuchillada.
		for i in 4:
			var t := fposmod(clock * 5 + i * 0.25, 1)
			draw_rect(Rect2(Vector2(16 + t * 17, -7 + sin(t * TAU) * 5).round(), Vector2(2, 2)), Color(hot, power * (0.85 if contact else 0.3)))
	for burst in bursts:
		var t: float = burst.age / 0.34
		var center := to_local(burst.point)
		var count := 14 if burst.strong else 8
		if OS.has_feature("web"): count = mini(count, 8)
		for i in count:
			var dir := Vector2.from_angle(float(i) * TAU / count + sin(i * 2.1) * 0.3)
			var point := center + dir * t * (35 if burst.strong else 22) + Vector2(0, t * t * 12)
			draw_line(point.round(), (point - dir * 6 * (1 - t)).round(), Color(1, 0.65, 0.2, 1 - t), 2)
			draw_rect(Rect2(point.round(), Vector2(2, 2)), Color(1, 1, 0.8, 1 - t))
		if burst.strong:
			draw_arc(center, 4 + t * 24, 0, TAU, 12, Color(1, 0.5, 0.1, (1 - t) * 0.7), 2)
