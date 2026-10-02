extends CanvasLayer
class_name OptionsScreen

# Pantalla de opciones con pestanas (Video, Audio, Efectos, Juego).
# Se abre desde el menu principal y desde el menu de pausa:
#     var s = preload("res://Scenes/UI/options_screen.tscn").instantiate()
#     add_child(s)   # o get_tree().root.add_child(s)
# Los valores viven en el autoload GameSettings. Para agregar una opcion: sumar la clave en
# GameSettings.DEFAULTS y la fila aca abajo en ROWS (tipo "toggle", "slider" u "opciones").

signal closed

const FONDO_SHADER = preload("res://Art/Menu/Animado/options_fondo.gdshader")
const COLOR_ACENTO := Color(0.35, 1.0, 0.85)

const TABS := [
	{"id": "video", "titulo": "Video"},
	{"id": "audio", "titulo": "Audio"},
	{"id": "fx", "titulo": "Efectos"},
	{"id": "juego", "titulo": "Juego"},
]

const ROWS := {
	"video": [
		{"tipo": "opciones", "clave": "modo_pantalla", "texto": "Modo de pantalla", "items": ["Pantalla completa", "Ventana", "Ventana sin bordes"], "valores": [0, 1, 2], "desc": "Pantalla completa, ventana común (1600x900) o ventana sin bordes del tamaño del monitor."},
		{"tipo": "toggle", "clave": "vsync", "texto": "Sincronización vertical (VSync)", "desc": "Evita el 'tearing' de la imagen. Si sentís los controles lentos, probá desactivarlo."},
		{"tipo": "opciones", "clave": "fps_max", "texto": "Límite de FPS", "items": ["Sin límite", "30", "60", "120", "144"], "valores": [0, 30, 60, 120, 144], "desc": "Limitar los cuadros por segundo baja el uso de la placa de video y la temperatura."},
		{"tipo": "toggle", "clave": "mostrar_fps", "texto": "Mostrar FPS", "desc": "Muestra un contador de cuadros por segundo arriba a la derecha."},
	],
	"audio": [
		{"tipo": "slider", "clave": "general", "texto": "Volumen general", "desc": "Volumen de todo el juego."},
		{"tipo": "slider", "clave": "music", "texto": "Música", "desc": "Volumen de la música."},
		{"tipo": "slider", "clave": "sfx", "texto": "Efectos de sonido", "desc": "Disparos, golpes, enemigos, interfaz y el resto de los efectos."},
		{"tipo": "toggle", "clave": "silenciar_sin_foco", "texto": "Silenciar al cambiar de ventana", "desc": "Silencia el juego cuando pasas a otra ventana (Alt+Tab)."},
	],
	"fx": [
		{"tipo": "toggle", "clave": "polvo_ambiente", "texto": "Polvo ambiente", "desc": "Partículas de polvo flotando en las salas. Desactivarlo mejora el rendimiento. Al reactivarlo vuelve desde la próxima sala."},
		{"tipo": "toggle", "clave": "luces_parpadeantes", "texto": "Luces parpadeantes", "desc": "Zumbido y fallas de las luces con chispas. Apagado, las luces quedan fijas."},
		{"tipo": "toggle", "clave": "vineta", "texto": "Viñeta cinematográfica", "desc": "Oscurece suavemente los bordes de la pantalla."},
		{"tipo": "toggle", "clave": "sombras", "texto": "Sombras", "desc": "Sombras debajo de personajes, enemigos y objetos."},
		{"tipo": "toggle", "clave": "polvo_pasos", "texto": "Polvo y huellas al caminar", "desc": "Partículas y huellas que deja el jugador al moverse."},
		{"tipo": "toggle", "clave": "sacudida_camara", "texto": "Sacudida de cámara", "desc": "Temblor de la cámara al recibir golpes y en explosiones."},
		{"tipo": "toggle", "clave": "animacion_salas", "texto": "Animación de entrada a las salas", "desc": "Los objetos y el piso aparecen con rebote al entrar a una sala. Apagado, la sala aparece ya armada."},
		{"tipo": "toggle", "clave": "particulas_menu", "texto": "Lluvia y nieve del menú", "desc": "Partículas del menú principal."},
		{"tipo": "toggle", "clave": "fondo_animado_menu", "texto": "Fondo animado del menú", "desc": "Respiración de Lázaro en el menú principal."},
	],
	"juego": [
		{"tipo": "toggle", "clave": "brujula_enemigos", "texto": "Brújula de enemigos", "desc": "Flechas en el borde de la pantalla que apuntan a los últimos enemigos fuera de cámara."},
		{"tipo": "toggle", "clave": "indicador_danio", "texto": "Indicador de dirección de daño", "desc": "Flecha roja que marca desde donde te golpearon."},
	],
}

var _root: Control
var _fondo: ColorRect
var _panel: PanelContainer
var _pages: Dictionary = {}
var _tab_buttons: Dictionary = {}
var _desc_label: Label
var _current_tab: String = ""
var _closing: bool = false
var _gs: Node

func _ready() -> void:
	layer = 105
	process_mode = Node.PROCESS_MODE_ALWAYS
	_gs = FxSettings.instance()
	_build_ui()
	_show_tab("video", false)
	_play_open_animation()

# ---------- construccion de la UI ----------

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_fondo = ColorRect.new()
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat = ShaderMaterial.new()
	mat.shader = FONDO_SHADER
	_fondo.material = mat
	_root.add_child(_fondo)

	# el CenterContainer mantiene el panel centrado en cualquier resolucion / modo ventana
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(1180, 780)
	_panel.add_theme_stylebox_override("panel", _make_panel_style())
	_panel.resized.connect(_on_panel_resized)
	center.add_child(_panel)

	var margin = MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	_panel.add_child(margin)

	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	margin.add_child(col)

	col.add_child(_make_title())
	col.add_child(_make_tab_bar())
	col.add_child(_make_separator())

	var holder = Control.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.custom_minimum_size = Vector2(0, 500) # entran las 9 filas de Efectos sin scroll
	col.add_child(holder)
	for tab in TABS:
		var page = _make_page(tab.id)
		holder.add_child(page)
		_pages[tab.id] = page

	_desc_label = Label.new()
	_desc_label.custom_minimum_size = Vector2(0, 52)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.add_theme_font_size_override("font_size", 18)
	_desc_label.add_theme_color_override("font_color", Color(0.72, 0.85, 0.83))
	col.add_child(_desc_label)

	col.add_child(_make_footer())

func _make_panel_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.035, 0.05, 0.065, 0.93)
	sb.border_color = Color(COLOR_ACENTO, 0.75)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
	sb.shadow_size = 24
	return sb

func _make_title() -> Label:
	var title = Label.new()
	title.text = "OPCIONES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.85, 1.0, 0.97))
	title.add_theme_constant_override("outline_size", 12)
	title.add_theme_color_override("font_outline_color", Color(COLOR_ACENTO, 0.35))
	# el titulo "late" despacio, como el logo
	var t = title.create_tween().set_loops()
	t.tween_property(title, "modulate", Color(1.15, 1.25, 1.25), 1.6).set_trans(Tween.TRANS_SINE)
	t.tween_property(title, "modulate", Color.WHITE, 1.6).set_trans(Tween.TRANS_SINE)
	return title

func _make_tab_bar() -> HBoxContainer:
	var bar = HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 14)
	var group = ButtonGroup.new()
	for i in TABS.size():
		var tab = TABS[i]
		var b = Button.new()
		b.text = tab.titulo
		b.toggle_mode = true
		b.button_group = group
		b.custom_minimum_size = Vector2(220, 60)
		b.add_theme_font_size_override("font_size", 26)
		b.focus_mode = Control.FOCUS_NONE
		# la pestaña activa queda resaltada con el color de acento
		b.add_theme_color_override("font_pressed_color", COLOR_ACENTO)
		b.add_theme_color_override("font_hover_pressed_color", COLOR_ACENTO)
		b.pressed.connect(_on_tab_pressed.bind(tab.id))
		bar.add_child(b)
		_tab_buttons[tab.id] = b
		ButtonFX.attach(b, i, 1.06)
	return bar

func _make_separator() -> ColorRect:
	var line = ColorRect.new()
	line.custom_minimum_size = Vector2(0, 2)
	line.color = Color(COLOR_ACENTO, 0.35)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line

func _make_page(tab_id: String) -> ScrollContainer:
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.visible = false
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	var rows: Array = ROWS.get(tab_id, [])
	for i in rows.size():
		list.add_child(_make_row(tab_id, rows[i], i))
	return scroll

func _make_row(section: String, data: Dictionary, index: int) -> PanelContainer:
	var row = PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 50)
	var normal = _make_row_style(index)
	var hover = _make_row_style(index)
	hover.bg_color = Color(COLOR_ACENTO, 0.10)
	hover.border_color = Color(COLOR_ACENTO, 0.55)
	row.add_theme_stylebox_override("panel", normal)
	row.mouse_entered.connect(_on_row_hover.bind(row, hover, data.desc))
	row.mouse_exited.connect(_on_row_unhover.bind(row, normal))

	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	row.add_child(h)

	var label = Label.new()
	label.text = data.texto
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	h.add_child(label)

	var control: Control
	match data.tipo:
		"toggle": control = _make_toggle(section, data)
		"slider": control = _make_slider(section, data)
		"opciones": control = _make_option(section, data)
	if control:
		h.add_child(control)
	return row

func _make_row_style(index: int) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.035 if index % 2 == 0 else 0.015)
	sb.border_color = Color(COLOR_ACENTO, 0.0)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb

func _make_toggle(section: String, data: Dictionary) -> CheckButton:
	var c = CheckButton.new()
	c.focus_mode = Control.FOCUS_NONE
	c.custom_minimum_size = Vector2(200, 0)
	c.button_pressed = bool(_get_setting(section, data.clave))
	c.text = "Activado" if c.button_pressed else "Desactivado"
	c.add_theme_font_size_override("font_size", 20)
	c.toggled.connect(_on_toggle_changed.bind(c, section, data.clave))
	return c

func _make_slider(section: String, data: Dictionary) -> HBoxContainer:
	var h = HBoxContainer.new()
	h.custom_minimum_size = Vector2(380, 0)
	h.add_theme_constant_override("separation", 14)
	var s = HSlider.new()
	s.min_value = 0
	s.max_value = 100
	s.step = 5
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.custom_minimum_size = Vector2(0, 30)
	s.focus_mode = Control.FOCUS_NONE
	s.value = float(_get_setting(section, data.clave))
	var pct = Label.new()
	pct.custom_minimum_size = Vector2(70, 0)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.text = "%d%%" % int(s.value)
	pct.add_theme_font_size_override("font_size", 22)
	s.value_changed.connect(_on_slider_changed.bind(pct, section, data.clave))
	h.add_child(s)
	h.add_child(pct)
	return h

func _make_option(section: String, data: Dictionary) -> OptionButton:
	var o = OptionButton.new()
	o.custom_minimum_size = Vector2(300, 44)
	o.focus_mode = Control.FOCUS_NONE
	o.add_theme_font_size_override("font_size", 20)
	o.get_popup().add_theme_font_size_override("font_size", 20)
	for item in data.items:
		o.add_item(item)
	var idx = data.valores.find(int(_get_setting(section, data.clave)))
	o.select(maxi(idx, 0))
	o.item_selected.connect(_on_option_selected.bind(section, data.clave, data.valores))
	return o

func _make_footer() -> HBoxContainer:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var reset = _make_footer_button("Restablecer pestaña")
	reset.pressed.connect(_on_reset_pressed)
	h.add_child(reset)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(spacer)
	var back = _make_footer_button("Volver")
	back.pressed.connect(close)
	h.add_child(back)
	ButtonFX.attach(reset, 0)
	ButtonFX.attach(back, 1)
	return h

func _make_footer_button(text: String) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(260, 60)
	b.add_theme_font_size_override("font_size", 24)
	b.focus_mode = Control.FOCUS_NONE
	return b

# ---------- valores ----------

func _get_setting(section: String, key: String) -> Variant:
	if _gs: return _gs.get_value(section, key)
	return FxSettings.DEFAULTS[section][key]

func _set_setting(section: String, key: String, value: Variant) -> void:
	if _gs: _gs.set_value(section, key, value)

func _on_toggle_changed(pressed: bool, c: CheckButton, section: String, key: String) -> void:
	c.text = "Activado" if pressed else "Desactivado"
	_set_setting(section, key, pressed)
	_play_ui_sound()

func _on_slider_changed(value: float, pct: Label, section: String, key: String) -> void:
	pct.text = "%d%%" % int(value)
	_set_setting(section, key, value)

func _on_option_selected(index: int, section: String, key: String, valores: Array) -> void:
	_set_setting(section, key, valores[index])
	_play_ui_sound()

func _on_reset_pressed() -> void:
	if not _gs: return
	_gs.reset_section(_current_tab)
	# rearma la pagina para que muestre los valores por defecto
	var old = _pages[_current_tab]
	var page = _make_page(_current_tab)
	old.get_parent().add_child(page)
	old.queue_free()
	_pages[_current_tab] = page
	_show_tab(_current_tab, true, true)

func _play_ui_sound() -> void:
	if has_node("/root/OptionsMenu") and get_node("/root/OptionsMenu").has_method("_play_hover_sound"):
		get_node("/root/OptionsMenu")._play_hover_sound()

# ---------- pestanas ----------

func _on_tab_pressed(tab_id: String) -> void:
	_show_tab(tab_id, true)

func _show_tab(tab_id: String, animate: bool, force: bool = false) -> void:
	if tab_id == _current_tab and not force: return
	_current_tab = tab_id
	_tab_buttons[tab_id].set_pressed_no_signal(true)
	_update_tab_highlight()
	_desc_label.text = ""
	for id in _pages:
		_pages[id].visible = id == tab_id
	if animate:
		_animate_page_rows(_pages[tab_id])

# la pestaña activa queda mas brillante y las demas un poco apagadas
func _update_tab_highlight() -> void:
	for id in _tab_buttons:
		var b: Button = _tab_buttons[id]
		var active = id == _current_tab
		b.modulate = Color(1.15, 1.25, 1.22) if active else Color(0.8, 0.85, 0.85)

# las filas entran en cascada
func _animate_page_rows(page: ScrollContainer) -> void:
	var list = page.get_child(0)
	var i = 0
	for row in list.get_children():
		row.modulate.a = 0.0
		var t = row.create_tween()
		t.tween_interval(i * 0.035)
		t.tween_property(row, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE)
		i += 1

func _on_row_hover(row: PanelContainer, style: StyleBox, desc: String) -> void:
	row.add_theme_stylebox_override("panel", style)
	_desc_label.text = desc

func _on_row_unhover(row: PanelContainer, style: StyleBox) -> void:
	row.add_theme_stylebox_override("panel", style)

# ---------- abrir / cerrar ----------

func _play_open_animation() -> void:
	var mat = _fondo.material as ShaderMaterial
	mat.set_shader_parameter("aparicion", 0.0)
	_panel.scale = Vector2(0.9, 0.9)
	_panel.modulate.a = 0.0
	var t = create_tween().set_parallel(true)
	t.tween_method(_set_fondo_aparicion, 0.0, 1.0, 0.3)
	t.tween_property(_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_panel, "modulate:a", 1.0, 0.25)
	_animate_page_rows(_pages[_current_tab])

func _on_panel_resized() -> void:
	_panel.pivot_offset = _panel.size / 2.0

func close() -> void:
	if _closing: return
	_closing = true
	var t = create_tween().set_parallel(true)
	t.tween_method(_set_fondo_aparicion, 1.0, 0.0, 0.25)
	t.tween_property(_panel, "scale", Vector2(0.92, 0.92), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_property(_panel, "modulate:a", 0.0, 0.2)
	t.chain().tween_callback(_on_closed)

func _on_closed() -> void:
	closed.emit()
	queue_free()

func _set_fondo_aparicion(value: float) -> void:
	(_fondo.material as ShaderMaterial).set_shader_parameter("aparicion", value)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
