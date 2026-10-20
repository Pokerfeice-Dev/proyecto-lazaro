extends Control
class_name InteractPrompt

## Cartel de interacción del mundo ("[E] Agarrar", "Costo: 30 Carne", etc.)
## con el estilo de la UI nueva: placa oscura con borde turquesa, la tecla
## dibujada como tecla y el texto aparte. Entra con un saltito y flota.
##
## No reemplaza la lógica de cada objeto: se cuelga del Label que ya usaban
## (cofres, puertas, carteles, terminales, Ygor, objetos) y lo copia. El Label
## sigue existiendo y se sigue prendiendo/apagando y cambiando de texto como
## antes; solo se vuelve invisible su texto y el cartel nuevo muestra lo mismo.
## Uso: InteractPrompt.mirror(mi_label)
##
## Con joystick, la tecla se cambia por el botón (E -> X, etc.; ver InputMode).
## Prioriza íconos sobre texto (como la UI nueva):
##   "[E] Agarrar" / "Presiona E: elegir equipo" -> tecla E + ícono de la acción
##       (si la acción no tiene ícono conocido, queda escrita)
##   "E"                                         -> solo la tecla
##   "Costo: 30 Carne" / "Te falta Carne (30)"   -> ícono de carne + número (rojo si falta)
##   "Cofre bloqueado (30 Carne)"                -> candado + carne + número
##   "Cofre", "Recompensa"                        -> no se muestran (sobra el texto)
##   "... enemigos"                               -> ícono de daño en color de aviso
##   cualquier otro texto (nombre de un objeto)  -> se deja escrito

const WORLD_SCALE := 0.4 # fuentes grandes achicadas: se ven nítidas con el zoom de la cámara
const FONT_TITLE := 28
const FONT_ACTION := 28
const FONT_DETAIL := 24
const BOB_HEIGHT := 3.0
const KEY_REGEX := "^\\s*(?:\\[([A-Za-z0-9]+)\\]|Presiona\\s+([A-Za-z0-9]+)\\s*:?)\\s*(.*)$"
const FLESH_REGEX := "(?i)(\\d+)\\s*carne|carne\\s*\\((\\d+)\\)"
const ICON_DIR := "res://Art/Ui/svg/"
const FLESH_ICON := "res://Art/Flesh/Flesh_icon.png"
const SCRAP_ICON := "res://Art/Scrap/Scrap_icon.png"
## palabra de la acción -> ícono (el primero que aparezca en el texto)
const ACTION_ICONS := [
	["desbloquear", "icon_lock"],
	["comprar", SCRAP_ICON],
	["agarrar", "icon_grab"],
	["recoger", "icon_grab"],
	["leer", "icon_info"],
	["hablar", "icon_info"],
	["mejoras", "icon_chevron_up"],
	["equipo", "icon_damage"],
	["siguiente", "icon_chevron_right"],
	["entrar", "icon_chevron_right"],
	["salir", "icon_chevron_left"],
]

var source: Label
var _last_text: String = ""
var _plate: PanelContainer
var _rows: VBoxContainer
var _pointer: ColorRect
var _regex := RegEx.new()
var _flesh_regex := RegEx.new()
var _time: float = 0.0
const HIDDEN_LINES := ["cofre", "recompensa"]

static func mirror(label: Label) -> InteractPrompt:
	if not label: return null
	var existing = label.get_node_or_null("InteractPrompt")
	if existing:
		return existing
	var prompt = InteractPrompt.new()
	prompt.name = "InteractPrompt"
	prompt.source = label
	label.add_child(prompt)
	return prompt

func _ready() -> void:
	_regex.compile(KEY_REGEX)
	_flesh_regex.compile(FLESH_REGEX)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	scale = Vector2(WORLD_SCALE, WORLD_SCALE)
	z_index = 60
	z_as_relative = false
	if source:
		source.self_modulate.a = 0.0 # el texto viejo queda oculto; sus hijos (este cartel) no
	_build()
	_sync_text()
	visibility_changed.connect(_on_visibility_changed)
	InputMode.instance().mode_changed.connect(_on_input_mode_changed)

# Teclado <-> joystick: se rearma para mostrar la tecla o el botón.
func _on_input_mode_changed(_gamepad: bool) -> void:
	_sync_text()

func _process(delta: float) -> void:
	if not source or not is_visible_in_tree(): return
	if source.text != _last_text:
		_sync_text()
	_time += delta
	position = Vector2(source.size.x / 2.0, source.size.y)
	_plate.position.y = -_plate.size.y - 14.0 + sin(_time * 3.0) * BOB_HEIGHT
	_pointer.visible = _plate.visible

# --- Armado ---

func _build() -> void:
	_plate = PanelContainer.new()
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.add_theme_stylebox_override("panel", _plate_style())
	add_child(_plate)
	_rows = VBoxContainer.new()
	_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rows.add_theme_constant_override("separation", 6)
	_plate.add_child(_rows)

	# rombito que "apunta" al objeto
	_pointer = ColorRect.new()
	_pointer.color = UIStyle.COLOR_TEAL
	_pointer.size = Vector2(10, 10)
	_pointer.pivot_offset = Vector2(5, 5)
	_pointer.rotation = PI / 4.0
	_pointer.position = Vector2(-5, -12)
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pointer)

func _plate_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.03, 0.08, 0.1, 0.88)
	s.border_color = Color(UIStyle.COLOR_TEAL, 0.7)
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 6
	return s

func _sync_text() -> void:
	_last_text = source.text if source else ""
	# se sacan ya (no solo queue_free): si no, el tamaño de la placa se calcula con
	# los renglones viejos todavía adentro y queda gigante
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	var first_plain = true
	for raw in _last_text.split("\n", false):
		var line = raw.strip_edges()
		if line.to_lower() in HIDDEN_LINES:
			continue
		var m = _regex.search(line)
		if line.length() == 1: # solo una tecla ("E" de los objetos del piso): tecla o botón
			_rows.add_child(_key_row(line.to_upper(), ""))
		elif m:
			var key = m.get_string(1) if m.get_string(1) != "" else m.get_string(2)
			_rows.add_child(_key_row(key.to_upper(), m.get_string(3).strip_edges()))
		elif _flesh_regex.search(line):
			_rows.add_child(_price_row(line))
		elif "enemigos" in line.to_lower():
			_rows.add_child(_icon(load(ICON_DIR + "icon_damage.svg"), 34.0, UIStyle.COLOR_WARNING))
		else:
			var color = UIStyle.COLOR_WARNING if "!" in line else (UIStyle.COLOR_GOLD if first_plain else UIStyle.COLOR_MUTED)
			_rows.add_child(_label(line, FONT_TITLE if first_plain else FONT_DETAIL, color))
			first_plain = false
	_plate.visible = _rows.get_child_count() > 0
	_fit_plate()

func _fit_plate() -> void:
	_plate.size = Vector2.ZERO
	_plate.reset_size()
	_plate.position.x = -_plate.size.x / 2.0

func _key_row(key: String, action: String) -> Control:
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	row.add_child(_keycap(key))
	if action == "":
		return row
	var price = _flesh_regex.search(action)
	var icon = _action_icon(action)
	if icon and not (price and "comprar" in action.to_lower()): # con precio, la carne ya dice "comprar"
		row.add_child(_icon(icon, 34.0, UIStyle.COLOR_TEXT))
	elif not icon:
		row.add_child(_label(action, FONT_ACTION, UIStyle.COLOR_TEXT))
	if price:
		row.add_child(_flesh_amount(_price_value(price), UIStyle.COLOR_GOLD))
	return row

# "Costo: 30 Carne" -> carne + 30; "Te falta Carne (30)" -> lo mismo en rojo con aviso.
func _price_row(line: String) -> Control:
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	var missing = "falta" in line.to_lower()
	if missing:
		row.add_child(_icon(load(ICON_DIR + "icon_warning.svg"), 30.0, UIStyle.COLOR_WARNING))
	elif "bloqueado" in line.to_lower():
		row.add_child(_icon(load(ICON_DIR + "icon_lock.svg"), 30.0, UIStyle.COLOR_GOLD))
	row.add_child(_flesh_amount(_price_value(_flesh_regex.search(line)), UIStyle.COLOR_WARNING if missing else UIStyle.COLOR_GOLD))
	return row

func _flesh_amount(amount: String, color: Color) -> Control:
	var box = HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	box.add_child(_icon(load(FLESH_ICON), 34.0, Color.WHITE))
	box.add_child(_label(amount, FONT_ACTION, color))
	return box

func _price_value(m: RegExMatch) -> String:
	return m.get_string(1) if m.get_string(1) != "" else m.get_string(2)

func _action_icon(action: String) -> Texture2D:
	var lower = action.to_lower()
	for pair in ACTION_ICONS:
		if pair[0] in lower:
			var icon_path = pair[1] if str(pair[1]).begins_with("res://") else ICON_DIR + pair[1] + ".svg"
			return load(icon_path)
	return null

func _icon(tex: Texture2D, icon_size: float, color: Color) -> TextureRect:
	var r = UIStyle.icon(tex, icon_size)
	r.modulate = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

func _keycap(key: String) -> Control:
	var pad = InputMode.pad_label(key)
	var cap: Control
	if InputMode.is_gamepad() and pad != key:
		cap = PadGlyph.create(pad, 44.0)
	else:
		cap = _key_plate(key)
	# la tecla late despacio para llamar la atención
	var t = cap.create_tween().set_loops()
	t.tween_property(cap, "modulate", Color(1.35, 1.35, 1.35), 0.6).set_trans(Tween.TRANS_SINE)
	t.tween_property(cap, "modulate", Color.WHITE, 0.6).set_trans(Tween.TRANS_SINE)
	return cap

func _key_plate(key: String) -> PanelContainer:
	var cap = PanelContainer.new()
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.custom_minimum_size = Vector2(44, 44)
	cap.add_theme_stylebox_override("panel", UIStyle.nine_slice(UIStyle.TEX_KEYCAP))
	var l = _label(key, 24, UIStyle.COLOR_TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cap.add_child(l)
	return cap

func _label(text: String, font_size: int, color: Color) -> Label:
	var l = UIStyle.label(text, font_size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4)
	return l

# --- Entrada con saltito cada vez que aparece ---

func _on_visibility_changed() -> void:
	if not is_visible_in_tree(): return
	_plate.pivot_offset = _plate.size / 2.0
	_plate.scale = Vector2(0.8, 0.8)
	_plate.modulate.a = 0.0
	var t = create_tween().set_parallel(true)
	t.tween_property(_plate, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_plate, "modulate:a", 1.0, 0.15)
