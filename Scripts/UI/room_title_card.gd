extends Control
class_name RoomTitleCard

## Cartel de entrada a una sala, con el estilo de la UI nueva. Una franja
## oscura se abre en el centro de la pantalla. Arriba aparece una línea chica
## dorada ("ZONA 2 · SALA 04"), el nombre grande se "decodifica" como en una
## terminal (caracteres al azar que se van fijando) y debajo se dibuja una
## línea turquesa con el subtítulo. Al irse, el nombre tiembla como con
## interferencia y todo se cierra.
## Uso: RoomTitleCard.show_in(capa, {"eyebrow": ..., "title": ..., "subtitle": ..., "accent": Color})

const TITLE_FONT := preload("res://Art/Fonts/Dekatron-SemiBold.otf")
const GLYPHS := "#%&@$*+=<>/?01"
const DECODE_TIME := 0.7
const HOLD_TIME := 1.6
const BAND_HEIGHT := 220.0

var data: Dictionary = {}

var _band: ColorRect
var _eyebrow: Label
var _title: Label
var _subtitle: Label
var _line_left: ColorRect
var _line_right: ColorRect
var _diamond: Control
var _final_text: String = ""
var _decode_t: float = -1.0
var _leaving: bool = false
var _tweens: Array[Tween] = []

static func show_in(parent: Node, p_data: Dictionary) -> RoomTitleCard:
	var card = RoomTitleCard.new()
	card.data = p_data
	parent.add_child(card)
	return card

func _ready() -> void:
	# Sigue andando con el juego en pausa: si se abre el inventario o la pausa
	# mientras está en pantalla, se va enseguida en vez de quedar congelado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	_play()

func _process(delta: float) -> void:
	if not _leaving and get_tree().paused:
		_vanish()
		return
	if _decode_t < 0.0: return
	_decode_t += delta
	var k = clampf(_decode_t / DECODE_TIME, 0.0, 1.0)
	_title.text = _scrambled(_final_text, k)
	if k >= 1.0:
		_decode_t = -1.0

# --- Armado ---

func _build() -> void:
	var accent: Color = data.get("accent", UIStyle.COLOR_TEAL)

	_band = ColorRect.new()
	_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band.color = Color(0.02, 0.06, 0.08, 0.8)
	_band.clip_contents = true
	_place(_band, 0.38, 0.0)
	_add_band_edge(accent, true)
	_add_band_edge(accent, false)
	add_child(_band)

	var box = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(box, 0.38, BAND_HEIGHT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	add_child(box)

	_eyebrow = _spaced_label(data.get("eyebrow", ""), 18, UIStyle.COLOR_GOLD, 5)
	box.add_child(_eyebrow)

	_final_text = String(data.get("title", ""))
	_title = Label.new()
	_title.text = ""
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_override("font", TITLE_FONT)
	_title.add_theme_font_size_override("font_size", 72)
	_title.add_theme_color_override("font_color", UIStyle.COLOR_TEXT)
	_title.add_theme_color_override("font_shadow_color", Color(accent, 0.55))
	_title.add_theme_constant_override("shadow_offset_x", 3)
	_title.add_theme_constant_override("shadow_offset_y", 0)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_title.add_theme_constant_override("outline_size", 6)
	box.add_child(_title)

	box.add_child(_build_rule(accent))
	_subtitle = _spaced_label(data.get("subtitle", ""), 16, UIStyle.COLOR_MUTED, 6)
	box.add_child(_subtitle)

# Filo fino arriba o abajo de la franja, del color de la sala.
func _add_band_edge(accent: Color, top: bool) -> void:
	var edge = ColorRect.new()
	edge.color = Color(accent, 0.35)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.anchor_left = 0.0
	edge.anchor_right = 1.0
	edge.anchor_top = 0.0 if top else 1.0
	edge.anchor_bottom = edge.anchor_top
	edge.offset_top = 0.0 if top else -1.0
	edge.offset_bottom = 1.0 if top else 0.0
	_band.add_child(edge)

# Ocupa todo el ancho, centrado en vertical a la altura relativa y_ratio.
func _place(node: Control, y_ratio: float, height: float) -> void:
	node.anchor_left = 0.0
	node.anchor_right = 1.0
	node.anchor_top = y_ratio
	node.anchor_bottom = y_ratio
	node.offset_left = 0.0
	node.offset_right = 0.0
	node.offset_top = -height / 2.0
	node.offset_bottom = height / 2.0

# Línea con un rombo al medio; cada mitad crece desde el centro.
func _build_rule(accent: Color) -> Control:
	var rule = HBoxContainer.new()
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.alignment = BoxContainer.ALIGNMENT_CENTER
	rule.add_theme_constant_override("separation", 10)
	_line_left = _rule_line(accent)
	_line_right = _rule_line(accent)
	_diamond = _make_diamond(UIStyle.COLOR_GOLD)
	rule.add_child(_line_left)
	rule.add_child(_diamond)
	rule.add_child(_line_right)
	return rule

func _rule_line(color: Color) -> ColorRect:
	var line = ColorRect.new()
	line.color = color
	line.custom_minimum_size = Vector2(0, 2)
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line

func _make_diamond(color: Color) -> Control:
	var d = ColorRect.new()
	d.color = color
	d.custom_minimum_size = Vector2(9, 9)
	d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	d.pivot_offset = Vector2(4.5, 4.5)
	d.rotation = PI / 4.0
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d

func _spaced_label(text: String, font_size: int, color: Color, spacing: int) -> Label:
	var font = FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.spacing_glyph = spacing
	var l = UIStyle.label(text, font_size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

# --- Animación ---

func _play() -> void:
	for node in [_eyebrow, _subtitle, _diamond]:
		node.modulate.a = 0.0
	_diamond.scale = Vector2.ZERO
	var line_width = clampf(_final_text.length() * 22.0, 180.0, 420.0)

	var t = _own_tween()
	# franja que se abre
	t.tween_method(_set_band_height, 0.0, BAND_HEIGHT, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_eyebrow, "modulate:a", 1.0, 0.3).set_delay(0.12)
	t.parallel().tween_property(_line_left, "custom_minimum_size:x", line_width, 0.5).set_delay(0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_line_right, "custom_minimum_size:x", line_width, 0.5).set_delay(0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_diamond, "modulate:a", 1.0, 0.2).set_delay(0.25)
	t.parallel().tween_property(_diamond, "scale", Vector2.ONE, 0.35).set_delay(0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_callback(func(): _decode_t = 0.0)
	t.tween_property(_subtitle, "modulate:a", 1.0, 0.4).set_delay(DECODE_TIME * 0.6)
	t.tween_interval(HOLD_TIME)
	t.tween_callback(_glitch_out)

func _glitch_out() -> void:
	if _leaving: return
	var t = _own_tween()
	for i in 5:
		t.tween_callback(_jitter.bind(i % 2 == 0))
		t.tween_interval(0.05)
	t.tween_callback(func(): _title.position.x = 0.0)
	t.tween_property(self, "modulate:a", 0.0, 0.35)
	t.parallel().tween_method(_set_band_height, BAND_HEIGHT, 0.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(_line_left, "custom_minimum_size:x", 0.0, 0.3)
	t.parallel().tween_property(_line_right, "custom_minimum_size:x", 0.0, 0.3)
	t.tween_callback(queue_free)

# Salida rápida cuando se abre un menú: corta las animaciones y se desvanece.
func _vanish() -> void:
	_leaving = true
	_decode_t = -1.0
	for t in _tweens:
		if t.is_valid():
			t.kill()
	var fade = create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.12)
	fade.tween_callback(queue_free)

# Interferencia: el nombre salta de costado y titila.
func _jitter(strong: bool) -> void:
	_title.position.x = randf_range(-14.0, 14.0) if strong else 0.0
	_title.modulate.a = 0.45 if strong else 1.0

# Tween guardado en la lista del cartel, para poder cortarlo en _vanish().
func _own_tween() -> Tween:
	var t = create_tween()
	_tweens.append(t)
	return t

func _set_band_height(h: float) -> void:
	_band.offset_top = -h / 2.0
	_band.offset_bottom = h / 2.0

# Texto que se "decodifica": las letras ya fijadas van de izquierda a derecha
# y el resto muestra caracteres al azar.
func _scrambled(text: String, k: float) -> String:
	var fixed = int(floor(text.length() * k))
	var out = text.substr(0, fixed)
	for i in range(fixed, text.length()):
		out += " " if text[i] == " " else GLYPHS[randi() % GLYPHS.length()]
	return out
