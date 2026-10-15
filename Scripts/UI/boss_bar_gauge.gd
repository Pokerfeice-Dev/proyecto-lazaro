extends Range
class_name BossBarGauge

## Barra de vida de jefe dibujada a mano: marco con puntas biseladas, relleno
## carmesí con degradé, "chip" claro que se queda un momento mostrando el
## daño recibido, marcas cada 10 % y muescas doradas en los umbrales de fase.
## Es un Range: los jefes le cambian "value" (o lo tween-ean) como antes.
## "reveal" (0..1) recorta el relleno: se usa para que se llene al aparecer.

const FRAME_COLOR := Color("#C9A45C")
const BACK_COLOR := Color(0.035, 0.025, 0.03, 0.94)
const EMPTY_COLOR := Color(0.13, 0.03, 0.045)
const FILL_TOP := Color("#FF5A52")
const FILL_BOTTOM := Color("#8E1020")
const CHIP_COLOR := Color("#FFE2A8")
const HEAL_COLOR := Color("#7CF0D8")
const CHIP_DELAY := 0.45
const CHIP_SPEED := 0.6 # fracción de barra por segundo
const INSET := 4.0

## Umbrales de fase (0..1). La muesca se apaga cuando la vida baja de ella.
var phase_marks: Array = []
var reveal := 1.0:
	set(v):
		reveal = v
		queue_redraw()

var _chip := 1.0
var _chip_wait := 0.0
var _flash := 0.0
var _heal_glow := 0.0
var _last_ratio := 1.0
var _time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_last_ratio = _ratio()
	_chip = _last_ratio
	value_changed.connect(_on_value_changed)

## Destello fuerte (cambio de fase).
func pulse() -> void:
	_flash = 1.6

## Toma el valor actual como punto de partida (sin destello ni chip).
func snap() -> void:
	_last_ratio = _ratio()
	_chip = _last_ratio
	_flash = 0.0
	_heal_glow = 0.0

func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(0.0, _flash - delta * 4.0)
	_heal_glow = maxf(0.0, _heal_glow - delta * 2.0)
	var fill_ratio = _ratio()
	if _chip > fill_ratio:
		_chip_wait -= delta
		if _chip_wait <= 0.0:
			_chip = maxf(fill_ratio, _chip - CHIP_SPEED * delta)
	queue_redraw()

func _on_value_changed(_v: float) -> void:
	var fill_ratio = _ratio()
	if fill_ratio < _last_ratio - 0.0001:
		_flash = 1.0
		_chip_wait = CHIP_DELAY
		_chip = maxf(_chip, _last_ratio)
	elif fill_ratio > _last_ratio + 0.0001:
		_chip = fill_ratio
		_heal_glow = 1.0
	_last_ratio = fill_ratio

func _ratio() -> float:
	if max_value <= min_value: return 0.0
	return clampf((value - min_value) / (max_value - min_value), 0.0, 1.0)

# --- Dibujo ---

func _draw() -> void:
	var w = size.x
	var h = size.y
	if w <= 1.0: return
	# mientras es solo una línea (al aparecer), se dibuja como la regla del cartel
	if h < 6.0:
		draw_rect(Rect2(0, 0, w, maxf(h, 1.0)), FRAME_COLOR)
		return
	var frame_alpha = clampf((h - 6.0) / 10.0, 0.0, 1.0)
	var outer = _bevel_rect(Rect2(0, 0, w, h))
	draw_colored_polygon(outer, BACK_COLOR)
	var inner_rect = Rect2(INSET, INSET, w - INSET * 2.0, h - INSET * 2.0)
	var inner = _bevel_rect(inner_rect)
	draw_colored_polygon(inner, EMPTY_COLOR)
	var fill_ratio = _ratio() * reveal
	if _chip * reveal > fill_ratio:
		_fill(inner, inner_rect, _chip * reveal, [CHIP_COLOR, CHIP_COLOR.darkened(0.25)])
	var low = _ratio() < 0.25
	var low_pulse = (0.5 + 0.5 * sin(_time * 7.0)) * 0.35 if low else 0.0
	var top = FILL_TOP.lerp(Color.WHITE, minf(_flash, 1.0) * 0.6 + low_pulse).lerp(HEAL_COLOR, _heal_glow * 0.6)
	var bottom = FILL_BOTTOM.lerp(Color(1, 0.5, 0.5), minf(_flash, 1.0) * 0.4)
	_fill(inner, inner_rect, fill_ratio, [top, bottom])
	_draw_shine(inner_rect, fill_ratio)
	_draw_ticks(inner_rect)
	var outline = outer.duplicate()
	outline.append(outer[0])
	draw_polyline(outline, Color(FRAME_COLOR, frame_alpha), 2.0, true)
	_draw_end_caps(w, h, frame_alpha)
	_draw_phase_marks(inner_rect, frame_alpha)

# Rectángulo con las puntas cortadas en diagonal (forma de hexágono alargado).
func _bevel_rect(r: Rect2) -> PackedVector2Array:
	var b = minf(r.size.y / 2.0, r.size.x / 2.0)
	return PackedVector2Array([
		r.position + Vector2(b, 0), r.position + Vector2(r.size.x - b, 0),
		r.position + Vector2(r.size.x, r.size.y / 2.0), r.position + Vector2(r.size.x - b, r.size.y),
		r.position + Vector2(b, r.size.y), r.position + Vector2(0, r.size.y / 2.0),
	])

# Relleno recortado a la forma interior, con degradé vertical (arriba, abajo).
func _fill(inner: PackedVector2Array, r: Rect2, fill_ratio: float, colors: Array) -> void:
	if fill_ratio <= 0.0: return
	var cut = PackedVector2Array([
		r.position, r.position + Vector2(r.size.x * fill_ratio, 0),
		r.position + Vector2(r.size.x * fill_ratio, r.size.y), r.position + Vector2(0, r.size.y),
	])
	for poly in Geometry2D.intersect_polygons(inner, cut):
		var cols = PackedColorArray()
		for p in poly:
			var k = clampf((p.y - r.position.y) / r.size.y, 0.0, 1.0)
			cols.append((colors[0] as Color).lerp(colors[1], k))
		draw_polygon(poly, cols)

func _draw_shine(r: Rect2, fill_ratio: float) -> void:
	if fill_ratio <= 0.0: return
	var b = r.size.y / 2.0
	var x0 = r.position.x + b * 0.5
	var x1 = r.position.x + maxf(b * 0.5, r.size.x * fill_ratio - b * 0.5)
	draw_line(Vector2(x0, r.position.y + 2), Vector2(x1, r.position.y + 2), Color(1, 1, 1, 0.28), 1.5)

func _draw_ticks(r: Rect2) -> void:
	for i in range(1, 10):
		var x = r.position.x + r.size.x * i / 10.0
		draw_line(Vector2(x, r.position.y + r.size.y * 0.55), Vector2(x, r.end.y), Color(0, 0, 0, 0.35), 1.0)

# Rombos dorados a los costados de la barra.
func _draw_end_caps(w: float, h: float, alpha: float) -> void:
	for x in [-10.0, w + 10.0]:
		var c = Vector2(x, h / 2.0)
		var s = 5.0
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, 0), c + Vector2(0, s), c + Vector2(-s, 0)]), Color(FRAME_COLOR, alpha))

# Muesca arriba y abajo en cada umbral de fase: dorada si falta, roja si ya pasó.
func _draw_phase_marks(r: Rect2, alpha: float) -> void:
	for mark in phase_marks:
		var x = r.position.x + r.size.x * float(mark)
		var passed = _ratio() <= float(mark)
		var col = Color("#E5484D") if passed else FRAME_COLOR
		col.a = alpha
		draw_colored_polygon(PackedVector2Array([Vector2(x - 5, -6), Vector2(x + 5, -6), Vector2(x, 2)]), col)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 5, size.y + 6), Vector2(x + 5, size.y + 6), Vector2(x, size.y - 2)]), col)
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color(col, 0.6 * alpha), 2.0)
