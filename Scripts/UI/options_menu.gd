extends CanvasLayer

## Menú de pausa (autoload OptionsMenu). Sigue la línea visual del inventario
## (ver UIStyle): ventana con paneles SVG, pestaña de título, columnas con
## recuadro y barra de atajos abajo. Se arma por código, como el inventario.
##   Izquierda: acciones (continuar, guardar, opciones, menú principal, salir).
##   Derecha: volumen de música y efectos, y un resumen de la run en curso.

# Los volúmenes se guardan aparte de la partida (GameSettings -> user://opciones.cfg).
const OPTIONS_SCREEN = preload("res://Scenes/UI/options_screen.tscn")
const MAIN_MENU_SCENE := "res://Scenes/UI/MainMenu.tscn"
const WINDOW_SIZE := Vector2(940, 560)
const ICON_COIN := preload("res://Art/Scrap/Scrap_icon.png")
const ICON_CLOSE := preload("res://Art/Ui/svg/icon_close.svg")
const ICON_MOUSE := preload("res://Art/Ui/svg/icon_mouse.svg")
const ICON_ZONE := preload("res://Art/Ui/svg/icon_info.svg")
const ICON_ROOM := preload("res://Art/Ui/svg/icon_range.svg")
const ICON_TIME := preload("res://Art/Ui/svg/icon_fire_rate.svg")
const ICON_KILLS := preload("res://Art/Ui/svg/icon_damage.svg")
const SAVE_TEXT := "GUARDAR PARTIDA"

var hover_audio: AudioStreamPlayer
var hover_stream = preload("res://Audio/Sfx/Piano_Ui (2).wav")

var is_open: bool = false
var was_paused: bool = false
var _is_animating: bool = false
var _options_screen: Node = null
var _sfx_preview_ready: bool = false

var _root: Control
var _backdrop: ColorRect
var _window: PanelContainer
var _scrap_label: Label
var _continue_btn: Button
var save_btn: Button
var volume_slider: HSlider
var sfx_slider: HSlider
var volume_value: Label
var sfx_value: Label
var _run_box: VBoxContainer
var _run_rows: VBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_init_audio()
	_build_ui()
	_load_volume_settings()
	get_tree().node_added.connect(_on_node_added)
	_bind_buttons(get_tree().root)
	visible = false

func _init_audio() -> void:
	hover_audio = AudioStreamPlayer.new()
	hover_audio.stream = hover_stream
	hover_audio.bus = "SFX"
	add_child(hover_audio)

# --- Sonido de hover en todos los botones del juego ---

func _on_node_added(node: Node) -> void:
	_bind_single_button(node)

func _bind_buttons(node: Node) -> void:
	_bind_single_button(node)
	for child in node.get_children():
		_bind_buttons(child)

func _bind_single_button(node: Node) -> void:
	if node is BaseButton and not node.mouse_entered.is_connected(_play_hover_sound):
		node.mouse_entered.connect(_play_hover_sound)
		node.focus_entered.connect(_play_focus_sound)

func _play_hover_sound() -> void:
	hover_audio.play()

# Con joystick, moverse entre botones suena igual que pasar el mouse por encima.
func _play_focus_sound() -> void:
	if InputMode.is_gamepad():
		hover_audio.play()

# --- Construcción de la ventana ---

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_backdrop = ColorRect.new()
	_backdrop.color = UIStyle.COLOR_BACKDROP
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_backdrop)

	_window = UIStyle.panel(UIStyle.TEX_PANEL_MAIN)
	_window.custom_minimum_size = WINDOW_SIZE
	_window.size = WINDOW_SIZE
	_root.add_child(_window)

	var inner = MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 24)
	inner.add_theme_constant_override("margin_right", 24)
	inner.add_theme_constant_override("margin_top", 20)
	inner.add_theme_constant_override("margin_bottom", 20)
	_window.add_child(inner)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	inner.add_child(vbox)

	_build_top_bar(vbox)
	_build_columns(vbox)
	_build_bottom_bar(vbox)

func _build_top_bar(parent: Control) -> void:
	var bar = HBoxContainer.new()
	parent.add_child(bar)

	var tabs = HBoxContainer.new()
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(UIStyle.title_tab("PAUSA"))
	bar.add_child(tabs)

	var right = HBoxContainer.new()
	right.add_theme_constant_override("separation", 24)
	bar.add_child(right)

	var coin_box = HBoxContainer.new()
	coin_box.add_theme_constant_override("separation", 8)
	coin_box.add_child(UIStyle.icon(ICON_COIN, 24))
	_scrap_label = UIStyle.label("0", 22, UIStyle.COLOR_GOLD)
	coin_box.add_child(_scrap_label)
	right.add_child(coin_box)

	var close_box = HBoxContainer.new()
	close_box.add_theme_constant_override("separation", 6)
	close_box.add_child(UIStyle.keycap("Esc"))
	var close_btn = Button.new()
	close_btn.text = "Cerrar"
	close_btn.icon = ICON_CLOSE
	close_btn.flat = true
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.add_theme_color_override("font_color", UIStyle.COLOR_MUTED)
	close_btn.add_theme_color_override("font_hover_color", UIStyle.COLOR_TEXT)
	close_btn.pressed.connect(close)
	close_box.add_child(close_btn)
	right.add_child(close_box)

func _build_columns(parent: Control) -> void:
	var columns = HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 16)
	parent.add_child(columns)

	var left = UIStyle.panel(UIStyle.TEX_PANEL_INSET)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 0.45
	columns.add_child(left)
	_build_actions_column(left)

	var right = UIStyle.panel(UIStyle.TEX_PANEL_INSET)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 0.55
	columns.add_child(right)
	_build_settings_column(right)

func _build_actions_column(container: Control) -> void:
	var m = UIStyle.padded(20)
	container.add_child(m)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	m.add_child(box)

	box.add_child(UIStyle.label("MENÚ", 24, UIStyle.COLOR_TEXT))
	box.add_child(UIStyle.label("Juego en pausa", 15, UIStyle.COLOR_GOLD))

	_continue_btn = _add_action(box, "CONTINUAR", true, close)
	save_btn = _add_action(box, SAVE_TEXT, false, _on_save_pressed)
	_add_action(box, "MÁS OPCIONES", false, _on_more_options_pressed)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	box.add_child(UIStyle.divider())

	_add_action(box, "VOLVER AL MENÚ PRINCIPAL", false, _on_menu_pressed)
	_add_action(box, "SALIR DEL JUEGO", false, _on_quit_pressed)

func _add_action(parent: Control, text: String, primary: bool, callback: Callable) -> Button:
	var btn = UIStyle.button(text, primary)
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn

func _build_settings_column(container: Control) -> void:
	var m = UIStyle.padded(20)
	container.add_child(m)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	m.add_child(box)

	box.add_child(UIStyle.label("AUDIO", 24, UIStyle.COLOR_TEXT))
	var music = _add_volume_row(box, "Música")
	volume_slider = music[0]
	volume_value = music[1]
	var sfx = _add_volume_row(box, "Efectos")
	sfx_slider = sfx[0]
	sfx_value = sfx[1]
	volume_slider.value_changed.connect(_on_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	volume_slider.drag_ended.connect(_on_slider_drag_ended)
	sfx_slider.drag_ended.connect(_on_sfx_drag_ended)

	_run_box = VBoxContainer.new()
	_run_box.add_theme_constant_override("separation", 10)
	box.add_child(_run_box)
	_run_box.add_child(UIStyle.divider())
	_run_box.add_child(UIStyle.label("PARTIDA ACTUAL", 20, UIStyle.COLOR_TEXT))
	_run_rows = VBoxContainer.new()
	_run_rows.add_theme_constant_override("separation", 6)
	_run_box.add_child(_run_rows)

# Devuelve [slider, etiqueta del porcentaje].
func _add_volume_row(parent: Control, title: String) -> Array:
	var head = HBoxContainer.new()
	var name_lbl = UIStyle.label(title, 18, UIStyle.COLOR_MUTED)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_lbl)
	var value_lbl = UIStyle.label("100%", 18, UIStyle.COLOR_TEXT)
	head.add_child(value_lbl)
	parent.add_child(head)

	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 5.0
	slider.custom_minimum_size.y = 24.0
	slider.focus_mode = Control.FOCUS_NONE # así las teclas del juego no lo mueven sin querer
	PadFocusable.attach(slider) # con joystick sí: la cruceta lo mueve
	UIStyle.style_slider(slider)
	parent.add_child(slider)
	return [slider, value_lbl]

func _build_bottom_bar(parent: Control) -> void:
	var bar = UIStyle.panel(UIStyle.TEX_PANEL_FOOTER)
	parent.add_child(bar)
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 36)
	bar.add_child(hbox)
	var mouse = _add_shortcut(hbox, UIStyle.icon(ICON_MOUSE, 24), "Seleccionar")
	KeycapSwitch.swap_icon(mouse, "A")
	_add_shortcut(hbox, UIStyle.keycap("Esc"), "Continuar")

func _add_shortcut(parent: Control, key: Control, action_text: String) -> Control:
	var item = HBoxContainer.new()
	item.add_theme_constant_override("separation", 8)
	item.add_child(key)
	item.add_child(UIStyle.label(action_text, 18, UIStyle.COLOR_MUTED))
	parent.add_child(item)
	return key

# --- Datos que cambian cada vez que se abre ---

func _refresh_data() -> void:
	_scrap_label.text = str(GameData.scrap)
	_refresh_run_summary()

# El resumen de la run solo tiene sentido en una sala de la run (LevelN_...).
func _refresh_run_summary() -> void:
	var scene = get_tree().current_scene
	var file = scene.scene_file_path.get_file().to_lower() if scene else ""
	_run_box.visible = file.begins_with("level")
	if not _run_box.visible: return
	for child in _run_rows.get_children():
		child.queue_free()
	_add_run_row(ICON_ZONE, "Zona", GameData.get_zone_name(GameData.current_level))
	_add_run_row(ICON_ROOM, "Sala", "Jefe" if "bossfight" in file else str(maxi(GameData.current_run_room, 1)))
	_add_run_row(ICON_TIME, "Tiempo", GameData.format_time(GameData.get_run_elapsed_seconds()))
	_add_run_row(ICON_KILLS, "Enemigos eliminados", str(GameData.run_enemies_killed))
	_add_run_row(ICON_COIN, "Chatarra obtenida", str(GameData.run_scrap_collected))

func _add_run_row(tex: Texture2D, title: String, value: String) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(UIStyle.icon(tex, 20))
	var name_lbl = UIStyle.label(title, 17, UIStyle.COLOR_MUTED)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)
	row.add_child(UIStyle.label(value, 17, UIStyle.COLOR_TEXT))
	_run_rows.add_child(row)

# --- Abrir y cerrar (entra desde abajo, como el inventario) ---

func _unhandled_input(event: InputEvent) -> void:
	if is_open and not is_instance_valid(_options_screen) and _is_pad_back(event):
		get_viewport().set_input_as_handled()
		close() # B del joystick
		return
	if not event.is_action_pressed("pause"): return
	if is_instance_valid(_options_screen): return # la pantalla de opciones se cierra sola con Esc
	if is_open:
		close()
		return
	var root = get_tree().root
	if root.has_node("WeaponSelectionMenu") or root.has_node("UpgradesMenu"):
		return
	open()

# B del joystick (Esc ya cierra por la acción "pause").
func _is_pad_back(event: InputEvent) -> bool:
	return event is InputEventJoypadButton and event.is_action_pressed("ui_cancel")

func open() -> void:
	if is_open or _is_animating: return
	is_open = true
	visible = true
	_load_volume_settings() # por si se cambiaron desde la pantalla de opciones
	_refresh_data()
	SceneTransition.set_menu_muffle(true)
	was_paused = get_tree().paused
	get_tree().paused = true
	PadFocus.push_modal(self, _continue_btn) # con joystick el foco queda en el menú
	_animate_in()

func close() -> void:
	if not is_open or _is_animating: return
	is_open = false
	_save_volume_settings()
	SceneTransition.set_menu_muffle(false)
	PadFocus.pop_modal(self)
	get_viewport().gui_release_focus()
	_animate_out()

func _window_rest_position() -> Vector2:
	return ((_root.get_viewport_rect().size - _window.size) / 2.0).floor()

func _animate_in() -> void:
	_is_animating = true
	var rest = _window_rest_position()
	_window.position = Vector2(rest.x, _root.get_viewport_rect().size.y)
	_backdrop.modulate.a = 0.0
	var fade = create_tween()
	fade.tween_property(_backdrop, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var slide = create_tween()
	slide.tween_property(_window, "position:y", rest.y, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	slide.tween_callback(_on_open_finished)

func _on_open_finished() -> void:
	_is_animating = false
	_continue_btn.grab_focus()

func _animate_out() -> void:
	_is_animating = true
	var fade = create_tween()
	fade.tween_property(_backdrop, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var slide = create_tween()
	slide.tween_property(_window, "position:y", _root.get_viewport_rect().size.y, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	slide.tween_callback(_on_close_finished)

func _on_close_finished() -> void:
	_is_animating = false
	visible = false
	if not was_paused:
		get_tree().paused = false

# --- Acciones ---

# "Más opciones": abre la pantalla completa de opciones arriba del menú de pausa.
func _on_more_options_pressed() -> void:
	if is_instance_valid(_options_screen): return
	_options_screen = OPTIONS_SCREEN.instantiate()
	_options_screen.closed.connect(_load_volume_settings)
	get_tree().root.add_child(_options_screen)

func _on_menu_pressed() -> void:
	close()
	SceneTransition.change_scene(MAIN_MENU_SCENE)

func _on_save_pressed() -> void:
	_play_hover_sound()
	GameData.save_game()
	save_btn.text = "¡PARTIDA GUARDADA!"
	var t = create_tween()
	t.tween_interval(2.0)
	t.tween_callback(func(): save_btn.text = SAVE_TEXT)

func _on_quit_pressed() -> void:
	get_tree().quit()

# --- Volumen (bus de música y bus de efectos) ---

func _on_volume_changed(value: float) -> void:
	_apply_bus_volume("Music", value)
	_update_volume_labels()

func _on_sfx_volume_changed(value: float) -> void:
	_apply_bus_volume("SFX", value)
	_update_volume_labels()

func _on_slider_drag_ended(_value_changed: bool) -> void:
	_save_volume_settings()

# Al soltar el slider de efectos suena un efecto de prueba, para escuchar el nivel elegido.
func _on_sfx_drag_ended(_value_changed: bool) -> void:
	_save_volume_settings()
	if _sfx_preview_ready:
		_play_hover_sound()

func _update_volume_labels() -> void:
	volume_value.text = "%d%%" % int(volume_slider.value)
	sfx_value.text = "%d%%" % int(sfx_slider.value)

# Los valores viven en GameSettings (se comparten con la pantalla de opciones del menú principal).
func _load_volume_settings() -> void:
	var music = 100.0
	var sfx = 100.0
	var gs = FxSettings.instance()
	if gs:
		music = float(gs.get_value("audio", "music"))
		sfx = float(gs.get_value("audio", "sfx"))
	volume_slider.set_value_no_signal(music)
	sfx_slider.set_value_no_signal(sfx)
	_apply_bus_volume("Music", music)
	_apply_bus_volume("SFX", sfx)
	_update_volume_labels()
	_sfx_preview_ready = true

func _save_volume_settings() -> void:
	var gs = FxSettings.instance()
	if not gs: return
	gs.set_value("audio", "music", volume_slider.value)
	gs.set_value("audio", "sfx", sfx_slider.value)

func _apply_bus_volume(bus_name: String, value: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1: return
	if value <= 0:
		AudioServer.set_bus_mute(bus_index, true)
		return
	AudioServer.set_bus_mute(bus_index, false)
	# Curva al cuadrado: el oído percibe el volumen de forma logarítmica, así el 50% suena
	# realmente a la mitad (-12 dB) en vez de casi igual que el 100% (-6 dB con la recta).
	var t = value / 100.0
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(t * t))
