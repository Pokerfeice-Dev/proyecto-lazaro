extends Node2D
## Indicador en espacio de mundo, independiente del giro y escala de la maza.
const CYAN := Color("52d8c6")
const GOLD := Color("f4c45e")
const RED := Color("ef5474")
var _active := false
var _phase := 1.0
var _window := 0.18
var _chain := 0
var _text := ""
var _text_time := 0.0
var _good := false
var _waves: Array[Dictionary] = []
var _style: StyleBoxFlat
var head_position := Vector2.ZERO

func _ready() -> void:
	z_index = 20
	_style = _panel()

func set_rhythm(active: bool, phase: float, timing: float, chain: int) -> void:
	_active = active
	_phase = phase
	_window = timing
	_chain = chain

func message(value: String, good: bool) -> void:
	_text = value
	_good = good
	_text_time = 0.6

func burst(center: Vector2, radius: float, contraction: bool) -> void:
	_waves.append({"center": center, "radius": radius, "contract": contraction, "age": 0.0})

func _process(delta: float) -> void:
	_text_time = maxf(0.0, _text_time - delta)
	for wave in _waves: wave.age += delta
	_waves = _waves.filter(func(wave: Dictionary) -> bool: return wave.age < 0.42)
	queue_redraw()

func _draw() -> void:
	var origin := Vector2(0, -57)
	if _active:
		var in_window := absf(_phase) <= _window
		var color := GOLD if in_window else CYAN
		var head := head_position - global_position
		if in_window:
			draw_arc(head, 15, 0, TAU, 24, Color(GOLD, 0.65), 1.0, true)
			for i in range(4):
				var ray := Vector2.from_angle(i * PI / 2.0)
				draw_line(head + ray * 18, head + ray * 22, GOLD, 1.0, true)
		draw_style_box(_style, Rect2(origin + Vector2(-43, -12), Vector2(86, 25)))
		draw_line(origin + Vector2(-35, 0), origin + Vector2(35, 0), Color(CYAN, 0.25), 1.0)
		draw_rect(Rect2(origin + Vector2(-35 * _window, -9), Vector2(70 * _window, 18)), Color(GOLD, 0.2))
		var points := PackedVector2Array([origin + Vector2(-12, 0), origin + Vector2(-6, 0), origin + Vector2(-3, 4), origin + Vector2(0, -8), origin + Vector2(3, 6), origin + Vector2(6, 0), origin + Vector2(12, 0)])
		draw_polyline(points, color, 1.5, true)
		var x := clampf(_phase, -1, 1) * 35.0
		draw_line(origin + Vector2(x, -10), origin + Vector2(x, 10), color, 2.0)
		for i in range(3):
			draw_circle(origin + Vector2((i - 1) * 9, 18), 2.5, GOLD if i < _chain else Color(CYAN, 0.25))
	if _text_time > 0:
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_string(font, origin + Vector2(-width / 2, -19), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(GOLD if _good else CYAN, minf(1, _text_time * 5)))
	for wave in _waves:
		var progress: float = wave.age / 0.42
		var radius: float = lerpf(wave.radius, 8, progress) if wave.contract else lerpf(8, wave.radius, progress)
		var center: Vector2 = wave.center - global_position
		var color := Color(GOLD if wave.contract else CYAN, (1.0 - progress) * 0.8)
		draw_arc(center, radius, 0, TAU, 64, Color(color, color.a * 0.15), 7, true)
		draw_arc(center, radius, 0, TAU, 64, color, 1.5, true)
		for i in range(12):
			var dir := Vector2.from_angle(i * TAU / 12.0 + progress * 0.4)
			draw_line(center + dir * radius, center + dir * (radius + 7), color, 1, true)

func _panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.06, 0.08, 0.9)
	style.border_color = Color(CYAN, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style
