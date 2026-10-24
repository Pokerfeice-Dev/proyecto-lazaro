extends Node2D
class_name CryptTelegraph

# Dibuja la anticipación y el golpe de los enemigos de La Cripta.
# El enemigo elige el estilo y alimenta el progreso de la carga cada frame.

enum Style { CONE, BEAM, AIM, RINGS, SUMMON }

const WARN := Color(1.0, 0.74, 0.28)
const DANGER := Color(1.0, 0.26, 0.2)
const LINE_W := 2.0
const DASH := 6.0

var style: Style = Style.CONE
var reach := 60.0
var angle_degrees := 100.0
var tint := DANGER
var direction := Vector2.RIGHT
var beam_length := 0.0
var beam_half_width := 10.0
var lock_ratio := 1.0
var pips := 1
var sustained := false
var summon_points := PackedVector2Array()

var _charging := false
var _progress := 0.0
var _strike := 0.0
var _strike_time := 0.3
var _time := 0.0
var _bursts: Array = []

func setup(new_style: Style, new_reach: float, new_tint: Color) -> void:
	style = new_style
	reach = new_reach
	tint = new_tint

func charge(progress: float) -> void:
	_charging = true
	_progress = clampf(progress, 0.0, 1.0)

func strike(duration: float) -> void:
	_charging = false
	_strike = 1.0
	_strike_time = maxf(duration, 0.05)
	if style == Style.BEAM:
		var scene = get_tree().current_scene if get_tree() else null
		if scene:
			DistortionShockwave.spawn(scene, global_position + direction * (beam_length * 0.5), beam_length * 0.45, 0.22, 0.035)

func stop() -> void:
	_charging = false

func clear() -> void:
	_charging = false
	_strike = 0.0
	_bursts.clear()
	queue_redraw()

# Destello corto en un punto local (boca del arma, aparición).
func flash_at(point: Vector2, size := 8.0) -> void:
	_bursts.append({"kind": "flash", "pos": point, "size": size, "life": 0.09, "max": 0.09})

# Onda expansiva en un punto local (campanada, invocación).
func ring_at(point: Vector2, size := 46.0) -> void:
	_bursts.append({"kind": "ring", "pos": point, "size": size, "life": 0.45, "max": 0.45})

func _process(delta: float) -> void:
	_time += delta
	_strike = maxf(0.0, _strike - delta / _strike_time)
	for burst in _bursts: burst.life -= delta
	_bursts = _bursts.filter(func(burst): return burst.life > 0.0)
	var parent_node := get_parent() as Node2D
	if parent_node and parent_node.scale.x != 0.0:
		scale = Vector2.ONE / parent_node.scale
	visible = _charging or _strike > 0.0 or not _bursts.is_empty()
	if visible: queue_redraw()

func _draw() -> void:
	if _charging:
		match style:
			Style.CONE: _draw_cone_charge()
			Style.BEAM: _draw_beam_charge()
			Style.AIM: _draw_aim_charge()
			Style.RINGS: _draw_rings_charge()
			Style.SUMMON: _draw_summon_charge()
	if _strike > 0.0:
		match style:
			Style.CONE: _draw_cone_strike()
			Style.BEAM: _draw_beam_strike()
	for burst in _bursts: _draw_burst(burst)

# --- Cono ---------------------------------------------------------------

func _draw_cone_charge() -> void:
	var color := _charge_color()
	var blink := _blink()
	_fill_sector(reach, Color(color, 0.09))
	_fill_sector(reach * _ease_out(_progress), Color(color, (0.16 + 0.16 * _progress) * blink))
	_dashed_arc(reach, Color(color, 0.6 * blink))
	_dashed_line(Vector2.ZERO, _edge(-1.0) * reach, Color(color, 0.45))
	_dashed_line(Vector2.ZERO, _edge(1.0) * reach, Color(color, 0.45))
	var front := reach * _ease_out(_progress)
	if front > 4.0:
		draw_arc(Vector2.ZERO, front, _from_angle(), _to_angle(), 18, Color(color.lightened(0.35), 0.9), LINE_W)
	_draw_chevrons(color)

func _draw_cone_strike() -> void:
	var color := tint.lightened(0.35)
	if sustained:
		var flicker := 0.75 + 0.25 * sin(_time * 38.0)
		_fill_sector(reach, Color(tint, 0.2 * flicker * minf(1.0, _strike * 5.0)))
		_dashed_arc(reach, Color(color, 0.55 * flicker))
		return
	var wave := reach * minf(1.0, 0.35 + (1.0 - _strike) * 1.8)
	_fill_sector(wave, Color(color, 0.45 * _strike))
	draw_arc(Vector2.ZERO, wave, _from_angle(), _to_angle(), 18, Color(1, 1, 1, _strike), LINE_W + 1.0)

func _draw_chevrons(color: Color) -> void:
	var side := direction.orthogonal()
	for index in 3:
		var t := fmod(_time * 1.4 + index / 3.0, 1.0)
		var center := direction * (14.0 + t * (reach - 22.0))
		var size := 4.0 + 2.0 * _progress
		var alpha := sin(t * PI) * (0.35 + 0.55 * _progress)
		var tip := center + direction * size
		draw_polyline(PackedVector2Array([center + side * size, tip, center - side * size]), Color(color.lightened(0.2), alpha), LINE_W)

# --- Rayo ---------------------------------------------------------------

func _draw_beam_charge() -> void:
	var locked := _progress >= lock_ratio
	var end := direction * beam_length
	var side := direction.orthogonal()
	draw_circle(Vector2.ZERO, 3.0 + 5.0 * _progress, Color(tint, 0.35 + 0.4 * _progress))
	if not locked:
		_dashed_line(direction * 10.0, end, Color(WARN, 0.55))
		_draw_reticle(end, 5.0, Color(WARN, 0.8))
		return
	var lock_t := inverse_lerp(lock_ratio, 1.0, _progress) if lock_ratio < 1.0 else 1.0
	var blink := 0.75 + 0.25 * signf(sin(_time * lerpf(18.0, 46.0, lock_t)))
	draw_line(direction * 8.0, end, Color(tint.lightened(0.25), blink), lerpf(2.0, 5.0, lock_t))
	for sign_value in [-1.0, 1.0]:
		var offset: Vector2 = side * beam_half_width * sign_value
		_dashed_line(direction * 12.0 + offset, end + offset, Color(tint, 0.55))
	_draw_reticle(end, 6.0 + 3.0 * lock_t, Color(tint.lightened(0.3), blink))

func _draw_beam_strike() -> void:
	var end := direction * beam_length
	var envelope := minf(1.0, _strike * 6.0) * minf(1.0, (1.0 - _strike) * 12.0 + 0.4)
	var jitter := 1.0 + 0.12 * sin(_time * 70.0)
	var width := beam_half_width * 2.0 * envelope * jitter
	draw_line(Vector2.ZERO, end, Color(tint, 0.3), width + 10.0)
	draw_line(Vector2.ZERO, end, Color(tint.lightened(0.15), 0.95), width)
	draw_line(Vector2.ZERO, end, Color(1, 0.95, 0.9, 1), maxf(1.0, width * 0.35))
	draw_circle(end, beam_half_width * 1.1 * envelope * jitter, Color(1, 0.9, 0.85, 0.9))
	draw_circle(Vector2.ZERO, beam_half_width * 0.9 * envelope, Color(1, 0.95, 0.9, 1))

# --- Disparo ------------------------------------------------------------

func _draw_aim_charge() -> void:
	var color := _charge_color()
	var length := minf(reach, 150.0)
	var end := direction * length
	var side := direction.orthogonal()
	_dashed_line(direction * 14.0, end, Color(color, 0.35 + 0.4 * _progress))
	var head := 5.0 + 2.0 * _progress
	draw_polyline(PackedVector2Array([end - direction * head + side * head, end, end - direction * head - side * head]), Color(color, 0.85 * _blink()), LINE_W)
	for index in pips:
		var lit := _progress >= float(index + 1) / float(pips + 1)
		var pip_pos := direction * (20.0 + index * 9.0)
		draw_rect(Rect2(pip_pos - Vector2(2, 2), Vector2(4, 4)), Color(color.lightened(0.3), 1.0 if lit else 0.25))

# --- Campanadas ---------------------------------------------------------

func _draw_rings_charge() -> void:
	var color := tint
	for index in 3:
		var t := fmod(_time * (0.9 + _progress) + index / 3.0, 1.0)
		draw_arc(Vector2.ZERO, 10.0 + t * 60.0, 0.0, TAU, 28, Color(color, (1.0 - t) * (0.3 + 0.5 * _progress)), LINE_W)
	draw_circle(Vector2.ZERO, 4.0 + 4.0 * _progress, Color(color, 0.25 * _blink()))

# --- Invocación ---------------------------------------------------------

func _draw_summon_charge() -> void:
	var color := tint
	for point in summon_points:
		_dashed_line(Vector2.ZERO, point, Color(color, 0.25))
		var radius := 7.0 + 9.0 * _ease_out(_progress)
		draw_circle(point, radius * 0.8, Color(color, 0.12 + 0.18 * _progress))
		_hexagon(point, radius, Color(color, 0.45 + 0.55 * _progress * _blink()))
		_hexagon(point, radius * 0.5, Color(color, 0.2 + 0.3 * _progress))

# --- Ráfagas ------------------------------------------------------------

func _draw_burst(burst: Dictionary) -> void:
	var t: float = 1.0 - burst.life / burst.max
	var pos: Vector2 = burst.pos
	var size: float = burst.size
	if burst.kind == "flash":
		var side := direction.orthogonal()
		var length := size * (1.0 - t * 0.5)
		var star := PackedVector2Array([pos + direction * length * 1.6, pos + side * length * 0.45, pos - direction * length * 0.4, pos - side * length * 0.45])
		draw_colored_polygon(star, Color(tint.lightened(0.4), 1.0 - t))
		draw_circle(pos, length * 0.35, Color(1, 1, 0.9, 1.0 - t))
		return
	draw_arc(pos, 6.0 + size * _ease_out(t), 0.0, TAU, 28, Color(tint.lightened(0.3), 1.0 - t), LINE_W + 1.0)

# --- Utilidades ---------------------------------------------------------

func _charge_color() -> Color:
	return WARN.lerp(tint, _progress)

func _blink() -> float:
	if _progress < 0.7: return 1.0
	return 0.6 + 0.4 * signf(sin(_time * 40.0))

func _ease_out(value: float) -> float:
	return 1.0 - pow(1.0 - value, 2.0)

func _from_angle() -> float:
	return direction.angle() - deg_to_rad(angle_degrees) * 0.5

func _to_angle() -> float:
	return direction.angle() + deg_to_rad(angle_degrees) * 0.5

func _edge(sign_value: float) -> Vector2:
	return direction.rotated(deg_to_rad(angle_degrees) * 0.5 * sign_value)

func _fill_sector(radius: float, color: Color) -> void:
	if radius < 2.0 or color.a <= 0.0: return
	var points := PackedVector2Array([Vector2.ZERO])
	for step in 17:
		points.append(Vector2.from_angle(lerpf(_from_angle(), _to_angle(), step / 16.0)) * radius)
	draw_colored_polygon(points, color)

func _dashed_arc(radius: float, color: Color) -> void:
	var span := _to_angle() - _from_angle()
	var steps := maxi(4, int(radius * span / DASH))
	for step in range(0, steps, 2):
		var a := _from_angle() + span * step / steps
		var b := _from_angle() + span * minf(step + 1, steps) / steps
		draw_arc(Vector2.ZERO, radius, a, b, 3, color, LINE_W)

func _dashed_line(from: Vector2, to: Vector2, color: Color) -> void:
	draw_dashed_line(from, to, color, LINE_W, DASH)

func _draw_reticle(center: Vector2, size: float, color: Color) -> void:
	draw_arc(center, size, 0.0, TAU, 16, color, LINE_W)
	draw_line(center + Vector2(size + 2, 0), center + Vector2(size + 6, 0), color, LINE_W)
	draw_line(center - Vector2(size + 2, 0), center - Vector2(size + 6, 0), color, LINE_W)
	draw_line(center + Vector2(0, size + 2), center + Vector2(0, size + 6), color, LINE_W)
	draw_line(center - Vector2(0, size + 2), center - Vector2(0, size + 6), color, LINE_W)

func _hexagon(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 7:
		points.append(center + Vector2.from_angle(TAU * index / 6.0 + PI / 6.0) * radius)
	draw_polyline(points, color, LINE_W)
