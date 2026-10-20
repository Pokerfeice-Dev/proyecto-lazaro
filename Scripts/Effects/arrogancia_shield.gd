extends Node2D

## Barrera visual: acompaña la ventana de reflejo, sin agregar colisiones.
const RADIUS := Vector2(28, 34)
const GOLD := Color(1.0, 0.82, 0.38)
const LIGHT := Color(0.65, 0.95, 1.0)
static var _sonic_stream: AudioStreamWAV
var active := false
var _opacity := 0.0
var _pulse := 1.0
var _time := 0.0
var _impacts: Array[Dictionary] = []
var _sound: AudioStreamPlayer2D

func _ready() -> void:
	name = "ArroganciaShield"
	position = Vector2(0, -8)
	z_index = 8
	visible = false
	_sound = AudioStreamPlayer2D.new()
	_sound.bus = "SFX"
	_sound.volume_db = -18.0
	_sound.max_distance = 700.0
	add_child(_sound)

func set_active(value: bool) -> void:
	if active == value: return
	active = value
	if active:
		visible = true
		_pulse = 0.0
		if not _sonic_stream:
			_sonic_stream = _build_sonic_sound()
		_sound.stream = _sonic_stream
		_sound.play()
	else:
		# El contorno desaparece al terminar la protección; sólo queda el pulso.
		_opacity = 0.0
	queue_redraw()

func reflect_at(world_position: Vector2) -> void:
	if not active: set_active(true)
	var direction = to_local(world_position).normalized()
	if direction == Vector2.ZERO: direction = Vector2.RIGHT
	if _impacts.size() >= 6: _impacts.pop_front()
	_impacts.append({"angle": direction.angle(), "age": 0.0})
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	_pulse = minf(1.0, _pulse + delta / 0.4)
	if active: _opacity = move_toward(_opacity, 1.0, delta * 14.0)
	for hit in _impacts: hit.age += delta
	_impacts = _impacts.filter(func(hit): return hit.age < 0.3)
	visible = active or _pulse < 1.0 or not _impacts.is_empty()
	if visible: queue_redraw()

func _ellipse(radius_scale: float, start: float = 0.0, end: float = TAU, segments: int = 48) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var angle = lerpf(start, end, float(i) / segments)
		points.append(Vector2.from_angle(angle) * RADIUS * radius_scale)
	return points

func _draw() -> void:
	if active:
		_draw_shield_body()
	if _pulse < 1.0:
		_draw_pulse()
	_draw_impacts()

func _draw_shield_body() -> void:
	var breathe = 0.85 + 0.15 * sin(_time * 5.0)
	draw_set_transform(Vector2.ZERO, 0.0, RADIUS)
	draw_circle(Vector2.ZERO, 1.0, Color(LIGHT, 0.045 * _opacity))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_polyline(_ellipse(1.0), Color(GOLD, 0.65 * _opacity * breathe), 1.2, true)
	draw_polyline(_ellipse(1.07), Color(LIGHT, 0.16 * _opacity), 2.0, true)
	for i in range(3):
		var angle = _time * 0.8 + TAU * float(i) / 3.0
		draw_polyline(_ellipse(0.94, angle, angle + 0.55, 10), Color(LIGHT, 0.7 * _opacity), 1.5, true)

func _draw_pulse() -> void:
	draw_polyline(_ellipse(0.8 + _pulse * 0.55), Color(LIGHT, (1.0 - _pulse) * 0.4), 1.4, true)

func _draw_impacts() -> void:
	for hit in _impacts:
		var progress: float = hit.age / 0.3
		var spread = 0.18 + progress * 0.45
		draw_polyline(_ellipse(1.0 + progress * 0.12, hit.angle - spread, hit.angle + spread, 12), Color(LIGHT, 1.0 - progress), 2.2 - progress, true)

## Pulso original sintetizado una sola vez: tono descendente con aire suave,
## ataque y salida amortiguados para evitar clics; sin bucle ni apilado de voces.
static func _build_sonic_sound() -> AudioStreamWAV:
	const RATE := 24000
	const LENGTH := 0.42
	var data := PackedByteArray()
	var samples := int(RATE * LENGTH)
	data.resize(samples * 2)
	var phase := 0.0
	var air := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 4187
	for i in range(samples):
		var t := float(i) / RATE
		var progress := t / LENGTH
		phase += TAU * lerpf(520.0, 180.0, progress) / RATE
		air = lerpf(air, rng.randf_range(-1.0, 1.0), 0.12)
		var envelope := minf(t / 0.025, 1.0) * pow(1.0 - progress, 2.0)
		var sample := (sin(phase) * 0.36 + sin(phase * 2.01) * 0.09 + air * 0.2) * envelope
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	return stream
