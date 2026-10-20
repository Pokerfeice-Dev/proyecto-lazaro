extends RefCounted
class_name CodexKit

## Piezas comunes de las pestañas del códice: arte de una entrada (en silueta
## si está bloqueada), nombre cifrado, descripción tachada, chips de stats y
## encabezados de sección. Cada pestaña (CodexBestiary, CodexArmory, ...) las
## combina con su propio diseño.

const LOCKED_SHADER := preload("res://Art/Ui/shaders/silueta_bloqueada.gdshader")
const ICON_LOCK := preload("res://Art/Ui/svg/icon_lock.svg")
const LOCKED_TEXT := Color("#4E6B73")
const REDACTED := Color("#1B3138")
const GLYPHS := "#%&@$*+=<>/?01"
const POSITIVE := Color("#7FE0A8")

static func entry(category: String, id: String) -> Dictionary:
	return CodexData.DATA.get(category, {}).get(id, {})

static func is_unlocked(category: String, id: String) -> bool:
	return GameData.is_codex_unlocked(category, id)

## Ícono estático de la entrada (recortado, a escala entera: ver PixelIcon).
## Bloqueado: silueta.
static func art(category: String, id: String, art_size: float, unlocked: bool, scale: int = PixelIcon.SLOT) -> TextureRect:
	var r = PixelIcon.make(entry(category, id).get("icon", null), art_size, scale)
	if not unlocked:
		r.material = silhouette(id)
	return r

static func silhouette(seed_text: String, blur: float = 1.0) -> ShaderMaterial:
	var mat = ShaderMaterial.new()
	mat.shader = LOCKED_SHADER
	mat.set_shader_parameter("blur", blur)
	mat.set_shader_parameter("phase", fmod(abs(seed_text.hash()) * 0.0001, 1.0))
	return mat

## Candado dorado centrado, para poner encima de un arte bloqueado.
static func lock_overlay(lock_size: float = 26.0) -> Control:
	var center = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lock = UIStyle.icon(ICON_LOCK, lock_size)
	lock.modulate = UIStyle.COLOR_GOLD
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(lock)
	return center

## Nombre de la entrada; bloqueada son caracteres cifrados (fijos por id).
static func title(category: String, id: String, unlocked: bool, font_size: int, color: Color = UIStyle.COLOR_GOLD) -> Label:
	var text = entry(category, id).get("name", "???")
	if not unlocked:
		text = cipher(id, clampi(text.length(), 5, 14))
	var l = UIStyle.label(text, font_size, color if unlocked else LOCKED_TEXT)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func cipher(seed_text: String, length: int) -> String:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_text.hash()
	var out = ""
	for i in length:
		out += GLYPHS[rng.randi() % GLYPHS.length()]
	return out

static func lore(text: String, font_size: int = 14, max_lines: int = 0) -> Label:
	var l = UIStyle.label(text, font_size, UIStyle.COLOR_MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if max_lines > 0:
		l.max_lines_visible = max_lines
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return l

## Bloques oscuros en lugar del texto, como un documento censurado.
static func redacted(seed_text: String, lines: int = 3) -> Control:
	var box = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_text.hash()
	for i in lines:
		var line = HBoxContainer.new()
		line.add_theme_constant_override("separation", 6)
		for w in rng.randi_range(2, 5):
			var block = ColorRect.new()
			block.color = REDACTED
			block.custom_minimum_size = Vector2(rng.randi_range(24, 80), 9)
			block.mouse_filter = Control.MOUSE_FILTER_IGNORE
			line.add_child(block)
		box.add_child(line)
	return box

## "Vida: 60 | Daño: 10" -> chips. Los "+x" van en verde y los "-x" en naranja.
static func stat_chips(stats: String, font_size: int = 12) -> Control:
	var flow = HFlowContainer.new()
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	for part in _split_stats(stats):
		flow.add_child(_chip(part, font_size))
	return flow

static func _split_stats(stats: String) -> Array:
	var sep = "|" if "|" in stats else ","
	var out = []
	for p in stats.split(sep, false):
		if p.strip_edges() != "":
			out.append(p.strip_edges())
	return out

static func _chip(text: String, font_size: int) -> Control:
	var chip = UIStyle.panel(UIStyle.TEX_SLOT["normal"])
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var color = UIStyle.COLOR_TEXT
	if text.begins_with("+"):
		color = POSITIVE
	elif text.begins_with("-"):
		color = UIStyle.COLOR_WARNING
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var colon = text.find(":")
	if colon > 0:
		row.add_child(UIStyle.label(text.substr(0, colon).to_upper(), font_size - 1, UIStyle.COLOR_MUTED))
		row.add_child(UIStyle.label(text.substr(colon + 1).strip_edges(), font_size, color))
	else:
		row.add_child(UIStyle.label(text, font_size, color))
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 4)
	m.add_theme_constant_override("margin_right", 4)
	m.add_child(row)
	chip.add_child(m)
	return chip

## Etiqueta corta con ícono (tipo de arma, rol, "JEFE"...).
static func tag(icon_tex: Texture2D, text: String, color: Color) -> Control:
	var row = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	if icon_tex:
		var ic = UIStyle.icon(icon_tex, 18)
		ic.modulate = color
		row.add_child(ic)
	row.add_child(UIStyle.label(text, 13, color))
	return row

static func section_header(icon_tex: Texture2D, text: String, count_text: String = "") -> Control:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var ic = UIStyle.icon(icon_tex, 22)
	ic.modulate = UIStyle.COLOR_TEAL
	row.add_child(ic)
	row.add_child(UIStyle.label(text, 16, UIStyle.COLOR_TEAL))
	if count_text != "":
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
		row.add_child(UIStyle.label(count_text, 13, UIStyle.COLOR_MUTED))
	box.add_child(row)
	box.add_child(UIStyle.divider())
	return box

## Fondo con un brillo radial (vitrina / pedestal) para el arte grande.
static func glow_backdrop(color: Color) -> TextureRect:
	var g = Gradient.new()
	g.set_color(0, Color(color, 0.32))
	g.set_color(1, Color(color, 0.0))
	var tex = GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.62)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 128
	tex.height = 128
	var r = TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

## Contenedor que apila hijos uno encima de otro, todos del mismo tamaño.
static func stack(min_size: Vector2) -> Control:
	var s = PanelContainer.new()
	s.custom_minimum_size = min_size
	s.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s

## Se agranda un poco al pasar el mouse o al llegar con la cruceta del joystick
## (con joystick la ficha se puede enfocar, así la lista acompaña la selección).
static func hover_pop(c: Control) -> void:
	var grow = func():
		c.pivot_offset = c.size / 2.0
		c.create_tween().tween_property(c, "scale", Vector2(1.04, 1.04), 0.12).set_trans(Tween.TRANS_SINE)
	var shrink = func():
		c.create_tween().tween_property(c, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE)
	c.mouse_entered.connect(grow)
	c.mouse_exited.connect(shrink)
	c.focus_entered.connect(grow)
	c.focus_exited.connect(shrink)
	PadFocusable.attach(c)

## Ficha que se elige con mouse o joystick: al enfocarla con la cruceta hace
## lo mismo que al pasarle el mouse por encima.
static func pad_select(btn: Control, on_select: Callable) -> void:
	btn.mouse_entered.connect(on_select)
	btn.focus_entered.connect(on_select)
	PadFocusable.attach(btn)
