extends Node2D
## Purely visual, bounded buffers. No collision, gameplay timers or screen shaders.
@export var continuous_lightning := true
@export_range(40.0, 180.0) var lightning_reach := 110.0
@export_range(0.04, 0.3) var lightning_interval := 0.11
var empowered := false
var _transition := 0.0
var _next_bolt := 0.0
var _shot_cooldown := 0.0
var _bolts: Array[Dictionary] = []
var _sparks: Array[Dictionary] = []
var _rings: Array[Dictionary] = []
var _cuts: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _web := false

func _ready() -> void:
	_rng.randomize()
	_web = OS.has_feature("web")
	z_index = 5
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func transform_phase(final_phase: bool) -> void:
	empowered = final_phase
	_transition = 2.0
	burst(global_position, 115.0 if final_phase else 80.0)

func stop() -> void:
	empowered = false
	_transition = 0.0
	_bolts.clear()
	_sparks.clear()
	_rings.clear()
	_cuts.clear()
	queue_redraw()

func _process(delta: float) -> void:
	_shot_cooldown -= delta
	_next_bolt -= delta
	if _transition > 0.0:
		_transition = maxf(0.0, _transition - delta)
		if _transition == 0.0: burst(global_position, 140.0 if empowered else 95.0)
	if (_transition > 0.0 or (empowered and continuous_lightning)) and _next_bolt <= 0.0:
		_next_bolt = lightning_interval * (1.4 if _web else 1.0)
		var count := 3 if _transition > 0.0 else 2
		for i in range(count):
			var angle := _rng.randf_range(-PI, PI)
			var origin := global_position + Vector2(_rng.randf_range(-12, 12), _rng.randf_range(-24, 14))
			bolt(origin, angle, lightning_reach * _rng.randf_range(0.55, 1.2), true)
		_spark(global_position, Vector2(_rng.randf_range(-25, 25), -70), 0.65)
	for collection in [_bolts, _sparks, _rings, _cuts]:
		for i in range(collection.size() - 1, -1, -1):
			collection[i].age += delta
			if collection[i].age >= collection[i].life: collection.remove_at(i)
	queue_redraw()

func bolt(origin: Vector2, angle: float, reach: float, attached: bool = false) -> void:
	if _bolts.size() >= (14 if _web else 24): _bolts.pop_front()
	var points := PackedVector2Array()
	var direction := Vector2.from_angle(angle)
	for i in range(7):
		var offset := direction * reach * float(i) / 6.0
		if i > 0 and i < 6: offset += direction.orthogonal() * _rng.randf_range(-16, 16)
		points.append(offset.snapped(Vector2(2, 2)))
	_bolts.append({"origin": origin - global_position if attached else origin, "attached": attached, "points": points, "age": 0.0, "life": _rng.randf_range(0.16, 0.27)})

func _spark(origin: Vector2, velocity: Vector2, life: float) -> void:
	if _sparks.size() >= (48 if _web else 96): _sparks.pop_front()
	_sparks.append({"origin": origin, "velocity": velocity, "age": 0.0, "life": life})

func burst(origin: Vector2, radius: float) -> void:
	if _rings.size() >= 8: _rings.pop_front()
	_rings.append({"origin": origin, "radius": radius, "age": 0.0, "life": 0.5})
	for i in range(8): bolt(origin, TAU * i / 8.0 + _rng.randf_range(-0.2, 0.2), radius)
	for i in range(18 if not _web else 10):
		_spark(origin, Vector2.from_angle(_rng.randf_range(-PI, PI)) * _rng.randf_range(50, 180), _rng.randf_range(0.25, 0.6))

func shot(origin: Vector2, angle: float) -> void:
	if _shot_cooldown > 0: return
	_shot_cooldown = 0.045
	bolt(origin, angle, 28.0)
	for i in range(4):
		_spark(origin, Vector2.from_angle(angle + _rng.randf_range(-0.65, 0.65)) * _rng.randf_range(70, 150), 0.2)

func slash(origin: Vector2, angle: float, radius: float, half_angle: float) -> void:
	if _cuts.size() >= 8: _cuts.pop_front()
	_cuts.append({"origin": origin, "angle": angle, "radius": radius, "half": half_angle, "age": 0.0, "life": 0.25})
	for i in range(5):
		var direction := angle + lerpf(-half_angle, half_angle, float(i) / 4.0)
		var edge := origin + Vector2.from_angle(direction) * radius * 0.75
		bolt(edge, direction, 26.0)
		_spark(edge, Vector2.from_angle(direction) * 100, 0.3)

func _draw() -> void:
	# Opaque black cores remain visible inside crimson edges (no additive black).
	for b in _bolts:
		var fade: float = 1.0 - b.age / b.life
		var origin: Vector2 = b.origin if b.attached else to_local(b.origin)
		var points := PackedVector2Array()
		for point in b.points: points.append(origin + point)
		draw_polyline(points, Color(0.85, 0.01, 0.08, fade * 0.2), 12.0)
		draw_polyline(points, Color(1.0, 0.02, 0.12, fade), 7.0)
		draw_polyline(points, Color(0.025, 0.005, 0.035, fade), 4.0)
		var branch := PackedVector2Array([points[3], points[3] + (points[4] - points[3]).rotated(0.9), points[3] + (points[5] - points[3]).rotated(0.8)])
		draw_polyline(branch, Color(0.95, 0.015, 0.08, fade), 3.0)
		draw_polyline(branch, Color(0.02, 0, 0.025, fade), 1.0)
	for p in _sparks:
		var fade: float = 1.0 - p.age / p.life
		var pos: Vector2 = to_local(p.origin + p.velocity * p.age)
		draw_rect(Rect2(pos.snapped(Vector2(2, 2)), Vector2(3, 3)), Color(1, 0.12 + fade * 0.5, 0.25, fade))
	for ring in _rings:
		var k: float = ring.age / ring.life
		var center := to_local(ring.origin)
		for segment in range(8):
			var a := TAU * segment / 8.0 + k * 0.2
			draw_arc(center, ring.radius * sqrt(k), a, a + 0.55, 5, Color(0.95, 0.03, 0.15, (1.0-k) * 0.7), 3.0)
	for cut in _cuts:
		var k: float = cut.age / cut.life
		var center := to_local(cut.origin)
		var start: float = cut.angle - cut.half + k * cut.half
		var finish: float = cut.angle + cut.half
		draw_arc(center, cut.radius, start, finish, 16, Color(1, 0.02, 0.15, 1-k), 9)
		draw_arc(center, cut.radius - 2, start, finish, 16, Color(0.02, 0, 0.03, 1-k), 5)
		draw_arc(center, cut.radius + 3, start, finish, 16, Color(1, 0.65, 0.7, 1-k), 2)
