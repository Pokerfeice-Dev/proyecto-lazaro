extends CanvasLayer
class_name RunEndScreen

## Pantalla de fin de run (muerte o victoria) con el estilo de la UI del juego:
## título grande, pestaña "RESUMEN DE LA RUN", panel con los datos (íconos,
## números que cuentan hacia arriba) y el botón para volver.
## Funciona con mouse, teclado (Enter o E) y joystick (el botón arranca
## enfocado y se aprieta con A).
## Uso:
##   RunEndScreen.show_death(get_tree())
##   RunEndScreen.show_victory(get_tree(), escena, titulo, subtitulo, al_volver)

const ICON_TIME := preload("res://Art/Ui/svg/icon_fire_rate.svg")
const ICON_ROOM := preload("res://Art/Ui/svg/icon_range.svg")
const ICON_KILLS := preload("res://Art/Ui/svg/icon_damage.svg")
const ICON_KILLER := preload("res://Art/Ui/svg/icon_warning.svg")
const ICON_SCRAP := preload("res://Art/Scrap/Scrap_icon.png")
const FONT_BIG := preload("res://Art/Fonts/Dekatron-SemiBold.otf")
const LAB_SCENE := "res://Scenes/Rooms/lab_room.tscn"
const COLOR_DEATH := Color("#E5484D")
const WINDOW_WIDTH := 600.0
const COUNT_TIME := 0.7
## Muertes con chiste (como los mensajes de muerte de Minecraft). La clave es
## el nombre de la fuente de daño; se elige una frase al azar.
const KILLER_JOKES := {
	"Tu propia gasolina": [
		"Lázaro comprobó que la gasolina sí es inflamable.",
		"Lázaro quiso ver la explosión desde la primera fila.",
		"Lázaro jugó con fuego. Literalmente.",
		"Lázaro olvidó que el disparo y la explosión eran en el mismo lugar.",
	],
}

var victory := false
var title_text := ""
var subtitle_text := ""
var next_scene := LAB_SCENE
var on_return: Callable
var _accent: Color
var _bg: ColorRect
var _header: VBoxContainer
var _window: VBoxContainer
var _rows: VBoxContainer
var _button: Button
var _leaving := false

static func show_death(tree: SceneTree) -> RunEndScreen:
	var s = RunEndScreen.new()
	s.title_text = "HAS MUERTO"
	s.subtitle_text = "VUÉLVETE MÁS FUERTE E INTÉNTALO DE NUEVO"
	tree.root.add_child(s)
	return s

## title / subtitle vacíos = textos de siempre. "callback" se llama justo antes
## de cambiar de escena (por ejemplo para descongelar al jugador).
static func show_victory(tree: SceneTree, scene: String, title: String = "", subtitle: String = "", callback: Callable = Callable()) -> RunEndScreen:
	var s = RunEndScreen.new()
	s.victory = true
	s.next_scene = scene
	s.title_text = title if title != "" else "¡HAS GANADO!"
	s.subtitle_text = subtitle if subtitle != "" else "COMPLETASTE LA RUN. VUELVE AL LABORATORIO A SEGUIR MEJORANDO"
	s.on_return = callback
	tree.root.add_child(s)
	return s

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_accent = UIStyle.COLOR_TEAL if victory else COLOR_DEATH
	_build()
	_fill_rows()
	PadFocus.push_modal(self, _button) # con joystick el botón arranca enfocado
	_animate_in()

func _input(event: InputEvent) -> void:
	if _leaving: return
	if not (event is InputEventKey and event.pressed and not event.echo): return
	if event.is_action_pressed("ui_accept") or event.physical_keycode == KEY_E:
		get_viewport().set_input_as_handled()
		_on_return()

# --- Armado ---

func _build() -> void:
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	_bg = ColorRect.new()
	_bg.color = Color(0.03, 0.0, 0.0) if not victory else Color(0.0, 0.03, 0.03)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_bg)
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 26)
	center.add_child(column)
	_header = _build_header()
	column.add_child(_header)
	_window = _build_window()
	column.add_child(_window)

func _build_header() -> VBoxContainer:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var title = Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_BIG)
	title.add_theme_font_size_override("font_size", 68)
	title.add_theme_color_override("font_color", UIStyle.COLOR_TEXT)
	title.add_theme_color_override("font_outline_color", _accent.darkened(0.45))
	title.add_theme_constant_override("outline_size", 10)
	box.add_child(title)
	var sub = UIStyle.label(subtitle_text, 18, _accent)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	return box

func _build_window() -> VBoxContainer:
	var window = VBoxContainer.new()
	window.add_theme_constant_override("separation", 0)
	window.custom_minimum_size.x = WINDOW_WIDTH
	var tab = UIStyle.title_tab("  RESUMEN DE LA RUN")
	tab.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tab.add_theme_font_size_override("font_size", 18)
	window.add_child(tab)
	var panel = UIStyle.panel(UIStyle.TEX_PANEL_MAIN)
	window.add_child(panel)
	var m = UIStyle.padded(26)
	panel.add_child(m)
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	m.add_child(col)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 10)
	col.add_child(_rows)
	col.add_child(UIStyle.divider())
	col.add_child(_build_footer())
	return window

func _build_footer() -> HBoxContainer:
	var footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	var key = UIStyle.keycap("E", "A")
	key.size_flags_vertical = Control.SIZE_SHRINK_CENTER # si no, se estira al alto del botón
	footer.add_child(key)
	_button = UIStyle.button("VOLVER AL LABORATORIO", true, Vector2(300, 52), 19)
	_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_button.pressed.connect(_on_return)
	footer.add_child(_button)
	return footer

# Datos de la run: muerte (con quién te mató) o victoria.
func _fill_rows() -> void:
	var time_text = GameData.format_time(GameData.get_run_elapsed_seconds())
	_add_row(ICON_TIME, "TIEMPO DE LA RUN" if victory else "TIEMPO SOBREVIVIDO", "", _text_value(time_text))
	if not victory:
		_add_row(ICON_ROOM, "SALAS RECORRIDAS", "", _text_value("1 - %d" % GameData.current_run_room))
	_add_row(ICON_KILLS, "ENEMIGOS ELIMINADOS", "", _count_value(GameData.run_enemies_killed))
	_add_row(ICON_SCRAP, "CHATARRA OBTENIDA", "EN ESTA RUN", _count_value(GameData.run_scrap_collected))
	if not victory:
		var killer = _text_value(GameData.last_killer)
		killer.add_theme_color_override("font_color", COLOR_DEATH)
		killer.add_theme_font_size_override("font_size", 22)
		_add_row(ICON_KILLER, "TE HA MATADO", "FUENTE DE DAÑO", killer)
		_add_joke(GameData.last_killer)

# Frase graciosa para algunas muertes (por ejemplo, con tu propia gasolina).
func _add_joke(killer: String) -> void:
	var jokes: Array = KILLER_JOKES.get(killer, [])
	if jokes.is_empty(): return
	var l = UIStyle.label(jokes.pick_random(), 16, UIStyle.COLOR_GOLD)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rows.add_child(l)

func _add_row(icon: Texture2D, title: String, subtitle: String, value: Control) -> void:
	if _rows.get_child_count() > 0:
		_rows.add_child(UIStyle.divider())
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.custom_minimum_size.y = 44
	var frame = UIStyle.panel(UIStyle.TEX_SLOT["normal"])
	frame.custom_minimum_size = Vector2(44, 44)
	var ic = UIStyle.icon(icon, 26)
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if icon != ICON_SCRAP: # el ícono de chatarra ya tiene sus colores
		ic.modulate = _accent
	frame.add_child(ic)
	row.add_child(frame)
	var texts = VBoxContainer.new()
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override("separation", 0)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_child(UIStyle.label(title, 17, UIStyle.COLOR_TEXT))
	if subtitle != "":
		texts.add_child(UIStyle.label(subtitle, 12, UIStyle.COLOR_MUTED))
	row.add_child(texts)
	value.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(value)
	_rows.add_child(row)

func _text_value(text: String) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT_BIG)
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", UIStyle.COLOR_TEXT)
	return l

# Número que cuenta desde 0 cuando aparece la fila.
func _count_value(amount: int) -> Label:
	var l = _text_value("0")
	l.set_meta("count_to", amount)
	return l

func _set_count(value: float, label: Label) -> void:
	label.text = str(int(value))

# --- Animaciones ---

func _animate_in() -> void:
	_bg.modulate.a = 0.0
	create_tween().tween_property(_bg, "modulate:a", 0.88, 0.6)
	_header.modulate.a = 0.0
	_window.modulate.a = 0.0
	for c in _rows.get_children():
		c.modulate.a = 0.0
	await get_tree().process_frame
	if not is_inside_tree(): return
	_slam_header()
	# la ventana está dentro de contenedores: se anima la escala, no la posición
	_window.pivot_offset = Vector2(_window.size.x / 2.0, 0.0)
	_window.scale = Vector2(0.94, 0.94)
	var t = create_tween().set_parallel(true)
	t.tween_property(_window, "modulate:a", 1.0, 0.3).set_delay(0.35)
	t.tween_property(_window, "scale", Vector2.ONE, 0.4).set_delay(0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_cascade_rows(0.6)

# El título cae grande y se asienta con un golpe.
func _slam_header() -> void:
	_header.pivot_offset = _header.size / 2.0
	_header.scale = Vector2(1.6, 1.6)
	var t = create_tween().set_parallel(true)
	t.tween_property(_header, "modulate:a", 1.0, 0.2)
	t.tween_property(_header, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Las filas entran una por una y los números cuentan hacia arriba.
func _cascade_rows(start: float) -> void:
	var delay = start
	for c in _rows.get_children():
		var t = create_tween()
		t.tween_interval(delay)
		t.tween_property(c, "modulate:a", 1.0, 0.18)
		for label in c.find_children("*", "Label", true, false):
			if label.has_meta("count_to"):
				var count = create_tween()
				count.tween_interval(delay)
				count.tween_method(_set_count.bind(label), 0.0, float(label.get_meta("count_to")), COUNT_TIME).set_ease(Tween.EASE_OUT)
		delay += 0.08

# --- Volver ---

func _on_return() -> void:
	if _leaving: return
	_leaving = true
	var t = create_tween().set_parallel(true)
	t.tween_property(_bg, "modulate:a", 0.0, 0.45)
	t.tween_property(_header, "modulate:a", 0.0, 0.3)
	t.tween_property(_window, "modulate:a", 0.0, 0.3)
	t.chain().tween_callback(_leave)

func _leave() -> void:
	if victory:
		if on_return.is_valid():
			on_return.call()
	else:
		GameData.clear_items()
	SceneTransition.change_scene(next_scene)
	queue_free()
