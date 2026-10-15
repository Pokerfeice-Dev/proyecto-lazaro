extends CanvasLayer
class_name BossPhaseBanner

## Cartel de cambio de fase de los jefes, con el mismo lenguaje que su entrada.
## Un destello del color del jefe, una franja que cruza la pantalla como un
## tajo, el número de la fase en romano que cae grande detrás (y tiembla al
## pegar), "FASE II" arriba, el nombre de la fase que se decodifica y una
## línea de detalle. Después la franja sigue de largo y todo se desvanece.
## Uso: BossPhaseBanner.show_phase(get_tree(), 2, "EL HAMBRE DESPIERTA", "REGENERACIÓN +25%")

const NAME_FONT := preload("res://Art/Fonts/CinzelDecorative-Bold.ttf")
const GLYPHS := "#%&@$*+=<>/?01"
const ROMAN := ["0", "I", "II", "III", "IV", "V"]
const Y_RATIO := 0.4
const BAND_HEIGHT := 190.0
const DECODE_TIME := 0.6
const HOLD_TIME := 1.9
const DEFAULT_ACCENT := Color("#E5484D")

var phase_number := 2
var title := ""
var subtitle := ""
var accent: Color = DEFAULT_ACCENT

var _root: Control
var _flash: ColorRect
var _band: Polygon2D
var _numeral: Label
var _eyebrow: Label
var _title: Label
var _subtitle: Label
var _decode_t := -1.0

static func show_phase(tree: SceneTree, p_phase: int, p_title: String, p_subtitle: String = "", p_accent: Color = DEFAULT_ACCENT) -> BossPhaseBanner:
	var banner = BossPhaseBanner.new()
	banner.phase_number = p_phase
	banner.title = p_title
	banner.subtitle = p_subtitle
	banner.accent = p_accent
	tree.current_scene.add_child(banner)
	return banner

func _init() -> void:
	layer = 105

func _ready() -> void:
	_build()
	_play()

func _process(delta: float) -> void:
	if _decode_t < 0.0: return
	_decode_t += delta
	var k = clampf(_decode_t / DECODE_TIME, 0.0, 1.0)
	_title.text = _scrambled(title, k)
	if k >= 1.0:
		_decode_t = -1.0

# --- Armado ---

func _vp() -> Vector2:
	return get_viewport().get_visible_rect().size

func _build() -> void:
	var vp = _vp()
	var cy = vp.y * Y_RATIO
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(accent, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_flash)
	_band = _make_band(vp.x, cy)
	_root.add_child(_band)
	_numeral = _make_label(ROMAN[clampi(phase_number, 0, ROMAN.size() - 1)], 260, Color(accent, 0.28), NAME_FONT, 0)
	_place(_numeral, cy - 6, 300)
	_root.add_child(_numeral)
	_eyebrow = _spaced_label("FASE " + ROMAN[clampi(phase_number, 0, ROMAN.size() - 1)], 22, UIStyle.COLOR_GOLD, 8)
	_place(_eyebrow, cy - 58, 34)
	_root.add_child(_eyebrow)
	_title = _make_label("", 66, Color("#F3E6CC"), NAME_FONT, 10)
	_title.add_theme_color_override("font_shadow_color", Color(accent, 0.7))
	_title.add_theme_constant_override("shadow_offset_y", 4)
	_place(_title, cy + 6, 96)
	_root.add_child(_title)
	_subtitle = _spaced_label(subtitle, 20, Color(UIStyle.COLOR_TEXT, 0.85), 6)
	_place(_subtitle, cy + 66, 30)
	_root.add_child(_subtitle)

# Franja inclinada (paralelogramo) con filos del color del jefe.
func _make_band(width: float, cy: float) -> Polygon2D:
	var h = BAND_HEIGHT / 2.0
	var slant = 60.0
	var band = Polygon2D.new()
	band.polygon = PackedVector2Array([Vector2(slant, -h), Vector2(width + slant * 2.0, -h), Vector2(width + slant, h), Vector2(0, h)])
	band.color = Color(0.03, 0.0, 0.02, 0.86)
	band.position = Vector2(-slant, cy)
	for edge_y in [-h, h - 3.0]:
		var edge = Polygon2D.new()
		var off = slant if edge_y < 0 else 0.0
		edge.polygon = PackedVector2Array([Vector2(off, edge_y), Vector2(width + slant + off, edge_y), Vector2(width + slant + off - 2.0, edge_y + 3.0), Vector2(off - 2.0, edge_y + 3.0)])
		edge.color = Color(accent, 0.75)
		band.add_child(edge)
	return band

func _make_label(text: String, size: int, color: Color, font: Font, outline: int) -> Label:
	var l = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_color_override("font_outline_color", Color(0.05, 0.0, 0.02, 0.95))
		l.add_theme_constant_override("outline_size", outline)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _spaced_label(text: String, size: int, color: Color, spacing: int) -> Label:
	var font = FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.spacing_glyph = spacing
	var l = _make_label(text, size, color, font, 4)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	return l

func _place(label: Label, center_y: float, height: float) -> void:
	label.size = Vector2(_vp().x, height)
	label.position = Vector2(0, center_y - height / 2.0)
	label.pivot_offset = label.size / 2.0

# --- Animación ---

func _play() -> void:
	var vp = _vp()
	_band.scale.x = 0.0
	for n in [_eyebrow, _title, _subtitle]:
		n.modulate.a = 0.0
	_numeral.modulate.a = 0.0
	_numeral.scale = Vector2(2.6, 2.6)
	var t = create_tween()
	# destello y tajo
	t.tween_property(_flash, "color:a", 0.38, 0.06)
	t.parallel().tween_property(_band, "scale:x", 1.0, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(_flash, "color:a", 0.0, 0.35)
	# el número cae y pega
	t.parallel().tween_property(_numeral, "modulate:a", 1.0, 0.12)
	t.parallel().tween_property(_numeral, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	t.tween_callback(_impact)
	t.parallel().tween_property(_eyebrow, "modulate:a", 1.0, 0.25)
	t.parallel().tween_property(_title, "modulate:a", 1.0, 0.15)
	t.tween_property(_subtitle, "modulate:a", 1.0, 0.35).set_delay(DECODE_TIME * 0.6)
	t.tween_interval(HOLD_TIME)
	# salida: la franja sigue de largo y todo se apaga
	t.tween_property(_band, "position:x", vp.x + 80.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(_numeral, "scale", Vector2(1.25, 1.25), 0.4)
	t.parallel().tween_property(_root, "modulate:a", 0.0, 0.4)
	t.tween_callback(queue_free)

# Golpe del número: tiembla, la franja vibra y arranca la decodificación del nombre.
func _impact() -> void:
	_decode_t = 0.0
	var t = create_tween()
	for i in 6:
		var off = Vector2(randf_range(-10, 10), randf_range(-6, 6)) * (1.0 - i / 6.0)
		t.tween_property(_root, "position", off, 0.035)
	t.tween_property(_root, "position", Vector2.ZERO, 0.04)
	for bar in get_tree().root.find_children("*", "CanvasLayer", true, false):
		if bar is BossHealthBar:
			bar.phase_pulse()

func _scrambled(text: String, k: float) -> String:
	var fixed = int(floor(text.length() * k))
	var out = text.substr(0, fixed)
	for i in range(fixed, text.length()):
		out += " " if text[i] == " " else GLYPHS[randi() % GLYPHS.length()]
	return out
