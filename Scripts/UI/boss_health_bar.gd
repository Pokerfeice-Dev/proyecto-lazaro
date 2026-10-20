extends CanvasLayer
class_name BossHealthBar

## Barra de vida de los jefes de zona, con su entrada animada.
## Entrada (intro = true): igual que el cartel de las salas, se abre una franja
## oscura, arriba aparece "ZONA X · NOMBRE DE LA ZONA", el nombre del jefe se
## decodifica en grande y debajo crece una línea dorada. Después todo vuela
## hacia arriba: el nombre se achica y queda sobre la barra, y la línea se
## engrosa hasta convertirse en la barra de vida, que se llena de izquierda a derecha.
## Sin intro: la barra baja desde arriba ya armada (por ejemplo, al volver a la fase 2).
## Uso: BossHealthBar.create(get_tree(), "El Primogénito", 2000, 2000, {"phase_marks": [0.4]})

const NAME_FONT := preload("res://Art/Fonts/CinzelDecorative-Bold.ttf")
const GLYPHS := "#%&@$*+=<>/?01"
const NAME_SIZE := 84
const NAME_FINAL_SCALE := 0.44
const BAR_WIDTH := 880.0
const BAR_HEIGHT := 22.0
const TOP_NAME_Y := 48.0
const TOP_BAR_Y := 86.0
const EYEBROW_FINAL_SCALE := 0.8
const INTRO_Y_RATIO := 0.3
const BAND_HEIGHT := 230.0
const DECODE_TIME := 0.8
const HOLD_TIME := 1.25
const MORPH_TIME := 0.75
const FILL_TIME := 0.8
const DEFAULT_ACCENT := Color("#E5484D")
const REVEAL_SOUND := "res://Audio/Sfx/Equipar_items.wav"

signal intro_finished

var gauge: BossBarGauge
var _root: Control
var _top_shade: TextureRect
var _band: ColorRect
var _eyebrow: Label
var _name: Label
var _subtitle: Label
var _diamond: ColorRect
var _final_name: String = ""
var _decode_t := -1.0
var _options: Dictionary = {}

## Crea la barra en la escena actual. options: "intro" (bool, por defecto true),
## "eyebrow", "subtitle", "accent" (Color) y "phase_marks" (umbrales 0..1).
static func create(tree: SceneTree, display_name: String, max_value: int, value: int, options: Dictionary = {}) -> BossHealthBar:
	var bar = BossHealthBar.new()
	bar._final_name = display_name
	bar._options = options
	tree.current_scene.add_child(bar)
	bar.gauge.max_value = max_value
	bar.gauge.value = value
	bar.gauge.snap()
	if options.get("intro", true):
		bar._play_intro()
	else:
		bar._play_quick()
	return bar

func _init() -> void:
	layer = 100

func _ready() -> void:
	_build()

func _process(delta: float) -> void:
	if _decode_t < 0.0: return
	_decode_t += delta
	var k = clampf(_decode_t / DECODE_TIME, 0.0, 1.0)
	_name.text = _scrambled(_final_name, k)
	if k >= 1.0:
		_decode_t = -1.0

## Sacudón y destello al cambiar de fase (lo llama BossPhaseBanner).
func phase_pulse() -> void:
	if gauge: gauge.pulse()
	var t = create_tween()
	for i in 5:
		t.tween_property(_root, "position", Vector2(randf_range(-6, 6), randf_range(-3, 3)) * (1.0 - i / 5.0), 0.04)
	t.tween_property(_root, "position", Vector2.ZERO, 0.05)

## Se va con un fundido (al morir el jefe).
func close() -> void:
	var t = create_tween()
	t.tween_property(_root, "modulate:a", 0.0, 0.4)
	t.tween_callback(queue_free)

# --- Armado ---

func _build() -> void:
	var accent: Color = _options.get("accent", DEFAULT_ACCENT)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_top_shade = _build_top_shade()
	_root.add_child(_top_shade)
	_band = ColorRect.new()
	_band.color = Color(0.03, 0.01, 0.02, 0.82)
	_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_band)
	for top in [true, false]:
		var edge = ColorRect.new()
		edge.color = Color(accent, 0.45)
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		edge.set_anchors_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		edge.offset_top = 0.0 if top else -1.0
		edge.offset_bottom = 1.0 if top else 0.0
		_band.add_child(edge)
	_eyebrow = _spaced_label(_options.get("eyebrow", _zone_eyebrow()), 20, UIStyle.COLOR_GOLD, 6)
	_root.add_child(_eyebrow)
	_name = Label.new()
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name.add_theme_font_override("font", NAME_FONT)
	_name.add_theme_font_size_override("font_size", NAME_SIZE)
	_name.add_theme_color_override("font_color", Color("#F3E6CC"))
	_name.add_theme_color_override("font_outline_color", Color(0.05, 0.0, 0.02, 0.95))
	_name.add_theme_constant_override("outline_size", 10)
	_name.add_theme_color_override("font_shadow_color", Color(accent, 0.6))
	_name.add_theme_constant_override("shadow_offset_x", 0)
	_name.add_theme_constant_override("shadow_offset_y", 4)
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_name)
	_subtitle = _spaced_label(_options.get("subtitle", "JEFE DE ZONA"), 18, UIStyle.COLOR_MUTED, 7)
	_root.add_child(_subtitle)
	gauge = BossBarGauge.new()
	gauge.phase_marks = _options.get("phase_marks", [])
	gauge.step = 0.1
	_root.add_child(gauge)
	_diamond = ColorRect.new()
	_diamond.color = UIStyle.COLOR_GOLD
	_diamond.size = Vector2(12, 12)
	_diamond.pivot_offset = Vector2(6, 6)
	_diamond.rotation = PI / 4.0
	_diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_diamond)

# Sombra arriba de la pantalla para que el nombre y la barra se lean sobre cualquier piso.
func _build_top_shade() -> TextureRect:
	var g = Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.8))
	g.set_color(1, Color(0, 0, 0, 0.0))
	var tex = GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 64
	var shade = TextureRect.new()
	shade.texture = tex
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.set_anchors_preset(Control.PRESET_TOP_WIDE)
	shade.offset_bottom = 170.0
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.modulate.a = 0.0
	return shade

# "ZONA 2 · LA CRIPTA": del nombre de la escena (LevelN_...) o de la zona actual.
func _zone_eyebrow() -> String:
	var scene = get_tree().current_scene
	var file = scene.scene_file_path.get_file().to_lower() if scene else ""
	var digits = ""
	if file.begins_with("level"):
		for c in file.substr(5):
			if not c.is_valid_int(): break
			digits += c
	var level = int(digits) if digits != "" else int(GameData.current_level)
	if level <= 0: return "AMENAZA DETECTADA"
	return "ZONA %d · %s" % [level, GameData.get_zone_name(level).to_upper()]

func _spaced_label(text: String, font_size: int, color: Color, spacing: int) -> Label:
	var font = FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.spacing_glyph = spacing
	var l = UIStyle.label(text, font_size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

# --- Posiciones (todo centrado en X; las etiquetas ocupan el ancho de la pantalla) ---

func _vp() -> Vector2:
	return get_viewport().get_visible_rect().size

func _center_label(label: Label, center_y: float, height: float) -> void:
	var vp = _vp()
	label.size = Vector2(vp.x, height)
	label.position = Vector2(0, center_y - height / 2.0)
	label.pivot_offset = label.size / 2.0

func _bar_rect_top() -> Rect2:
	var w = minf(BAR_WIDTH, _vp().x * 0.6)
	return Rect2(_vp().x / 2.0 - w / 2.0, TOP_BAR_Y - BAR_HEIGHT / 2.0, w, BAR_HEIGHT)

func _place_final() -> void:
	_center_label(_name, TOP_NAME_Y, 120)
	_name.scale = Vector2.ONE * NAME_FINAL_SCALE
	_center_label(_eyebrow, TOP_BAR_Y + 30, 30)
	_eyebrow.scale = Vector2.ONE * EYEBROW_FINAL_SCALE
	_top_shade.modulate.a = 1.0
	var r = _bar_rect_top()
	gauge.position = r.position
	gauge.size = r.size

# --- Entrada con título ---

func _play_intro() -> void:
	_vanish_room_cards()
	var vp = _vp()
	var cy = vp.y * INTRO_Y_RATIO
	_set_band(0.0, cy)
	_center_label(_eyebrow, cy - 70, 30)
	_center_label(_name, cy - 4, 120)
	_center_label(_subtitle, cy + 74, 30)
	_name.text = ""
	_final_name = _final_name.strip_edges()
	var rule_w = clampf(_final_name.length() * 34.0, 360.0, 720.0)
	gauge.size = Vector2(0, 2)
	gauge.position = Vector2(vp.x / 2.0, cy + 50)
	gauge.reveal = 0.0
	_diamond.position = Vector2(vp.x / 2.0 - 6, cy + 45)
	for n in [_eyebrow, _subtitle, _diamond]:
		n.modulate.a = 0.0
	_diamond.scale = Vector2.ZERO
	var t = create_tween()
	t.tween_method(_set_band.bind(cy), 0.0, BAND_HEIGHT, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_eyebrow, "modulate:a", 1.0, 0.3).set_delay(0.12)
	t.parallel().tween_property(gauge, "size:x", rule_w, 0.55).set_delay(0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(gauge, "position:x", vp.x / 2.0 - rule_w / 2.0, 0.55).set_delay(0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_diamond, "modulate:a", 1.0, 0.2).set_delay(0.25)
	t.parallel().tween_property(_diamond, "scale", Vector2.ONE, 0.35).set_delay(0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_callback(_finish_decoding)
	t.tween_property(_subtitle, "modulate:a", 1.0, 0.4).set_delay(DECODE_TIME * 0.6)
	t.tween_interval(HOLD_TIME)
	t.tween_callback(_morph_to_bar)

func _finish_decoding() -> void:
	_decode_t = 0.0

# El cartel se convierte en la barra: todo sube a su lugar arriba de la pantalla.
func _morph_to_bar() -> void:
	_decode_t = -1.0
	_name.text = _final_name
	var vp = _vp()
	var r = _bar_rect_top()
	var cy = vp.y * INTRO_Y_RATIO
	var t = create_tween().set_parallel(true)
	t.tween_method(_set_band.bind(cy), BAND_HEIGHT, 0.0, MORPH_TIME * 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(_subtitle, "modulate:a", 0.0, 0.25)
	t.tween_property(_diamond, "modulate:a", 0.0, 0.2)
	t.tween_property(_name, "position:y", TOP_NAME_Y - 60.0, MORPH_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_name, "scale", Vector2.ONE * NAME_FINAL_SCALE, MORPH_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_eyebrow, "position:y", TOP_BAR_Y + 30 - 15.0, MORPH_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_eyebrow, "scale", Vector2.ONE * EYEBROW_FINAL_SCALE, MORPH_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_top_shade, "modulate:a", 1.0, MORPH_TIME)
	t.tween_property(gauge, "position", r.position, MORPH_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(gauge, "size", r.size, MORPH_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.chain().tween_callback(_play(REVEAL_SOUND))
	t.chain().tween_property(gauge, "reveal", 1.0, FILL_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.chain().tween_callback(_finish_intro)

# --- Entrada sin título ---

func _play_quick() -> void:
	_band.visible = false
	_subtitle.visible = false
	_diamond.visible = false
	_name.text = _final_name
	_place_final()
	_root.modulate.a = 0.0
	_root.position.y = -40.0
	var t = create_tween().set_parallel(true)
	t.tween_property(_root, "modulate:a", 1.0, 0.4)
	t.tween_property(_root, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.chain().tween_callback(_finish_intro)

func _finish_intro() -> void:
	_band.visible = false
	_subtitle.visible = false
	_diamond.visible = false
	_place_final()
	intro_finished.emit()

# --- Utilidades ---

func _set_band(h: float, cy: float) -> void:
	_band.position = Vector2(0, cy - h / 2.0)
	_band.size = Vector2(_vp().x, h)

# El cartel común de la sala no se superpone con el del jefe.
func _vanish_room_cards() -> void:
	for node in get_tree().root.find_children("*", "Control", true, false):
		if node is RoomTitleCard:
			node._vanish()

func _scrambled(text: String, k: float) -> String:
	var fixed = int(floor(text.length() * k))
	var out = text.substr(0, fixed)
	for i in range(fixed, text.length()):
		out += " " if text[i] == " " else GLYPHS[randi() % GLYPHS.length()]
	return out

func _play(path: String) -> Callable:
	return func():
		if not ResourceLoader.exists(path): return
		var sfx = AudioStreamPlayer.new()
		sfx.stream = load(path)
		sfx.bus = "SFX"
		sfx.volume_db = -4.0
		add_child(sfx)
		sfx.play()
		sfx.finished.connect(sfx.queue_free)
