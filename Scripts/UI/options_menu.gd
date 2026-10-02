extends CanvasLayer

@onready var menu_control: Control = $MenuControl
@onready var volume_slider: HSlider = $MenuControl/VBoxContainer/VolumeSlider
@onready var sfx_slider: HSlider = $MenuControl/VBoxContainer/SfxSlider
@onready var close_btn: Button = $MenuControl/VBoxContainer/CloseButton
@onready var menu_btn: Button = $MenuControl/VBoxContainer/MenuButton
@onready var quit_btn: Button = $MenuControl/VBoxContainer/QuitButton
@onready var volume_label: Label = $MenuControl/VBoxContainer/VolumeLabel
@onready var sfx_label: Label = $MenuControl/VBoxContainer/SfxLabel

# Los volumenes se guardan aparte de la partida (GameSettings -> user://opciones.cfg).
const OPTIONS_SCREEN = preload("res://Scenes/UI/options_screen.tscn")
var _options_screen: Node = null
var _sfx_preview_ready: bool = false

var hover_audio: AudioStreamPlayer
var hover_stream = preload("res://Audio/Sfx/Piano_Ui (2).wav")

var is_open: bool = false
var was_paused: bool = false
var save_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_init_audio()
	_setup_volume_sliders()
	_load_volume_settings()
	_connect_signals()
	
	get_tree().node_added.connect(_on_node_added)
	
	save_btn = Button.new()
	save_btn.text = "Guardar partida"
	save_btn.pressed.connect(_on_save_pressed)
	$MenuControl/VBoxContainer.add_child(save_btn)
	# se calcula el índice en vez de un número fijo, para no depender del orden de los demás nodos
	$MenuControl/VBoxContainer.move_child(save_btn, close_btn.get_index() + 1)
	
	_create_more_options_button()
	
	_bind_buttons(get_tree().root)
	
	self.visible = false

func _init_audio() -> void:
	hover_audio = AudioStreamPlayer.new()
	hover_audio.stream = hover_stream
	hover_audio.bus = "SFX"
	add_child(hover_audio)

func _connect_signals() -> void:
	volume_slider.value_changed.connect(_on_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	volume_slider.drag_ended.connect(_on_slider_drag_ended)
	sfx_slider.drag_ended.connect(_on_sfx_drag_ended)
	close_btn.pressed.connect(close)
	menu_btn.pressed.connect(_on_menu_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

func _on_node_added(node: Node) -> void:
	_bind_single_button(node)

func _bind_buttons(node: Node) -> void:
	_bind_single_button(node)
	for child in node.get_children():
		_bind_buttons(child)

func _bind_single_button(node: Node) -> void:
	if node is BaseButton:
		if not node.mouse_entered.is_connected(_play_hover_sound):
			node.mouse_entered.connect(_play_hover_sound)

func _play_hover_sound() -> void:
	hover_audio.play()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if is_instance_valid(_options_screen): return # la pantalla de opciones se cierra sola con Esc
		if is_open:
			close()
		else:
			var root = get_tree().root
			if root.has_node("WeaponSelectionMenu") or root.has_node("UpgradesMenu"):
				return
			open()

func open() -> void:
	if is_open: return
	is_open = true
	self.visible = true
	_load_volume_settings() # por si se cambiaron desde la pantalla de opciones
	SceneTransition.set_menu_muffle(true)
	
	if not get_tree().paused:
		was_paused = false
		get_tree().paused = true
	else:
		was_paused = true
	
	menu_control.pivot_offset = menu_control.get_viewport_rect().size / 2.0
	menu_control.scale = Vector2.ZERO
	menu_control.modulate.a = 0.0 # Fade sumado al scale existente, entrada más prolija.
	var tween = create_tween().set_parallel(true)
	tween.tween_property(menu_control, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(menu_control, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func close() -> void:
	if not is_open: return
	is_open = false
	_save_volume_settings()
	SceneTransition.set_menu_muffle(false)
	var tween = create_tween().set_parallel(true) # Fade + scale de salida en paralelo.
	tween.tween_property(menu_control, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(menu_control, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(_on_close_finished)

func _on_close_finished() -> void:
	self.visible = false
	if not was_paused:
		get_tree().paused = false

# ---- "Más opciones": abre la pantalla completa de opciones arriba del menu de pausa ----
func _create_more_options_button() -> void:
	var b = Button.new()
	b.text = "Más opciones"
	b.pressed.connect(_on_more_options_pressed)
	$MenuControl/VBoxContainer.add_child(b)
	$MenuControl/VBoxContainer.move_child(b, close_btn.get_index())

func _on_more_options_pressed() -> void:
	if is_instance_valid(_options_screen): return
	_options_screen = OPTIONS_SCREEN.instantiate()
	_options_screen.closed.connect(_load_volume_settings)
	get_tree().root.add_child(_options_screen)

func _on_menu_pressed() -> void:
	close()
	SceneTransition.change_scene("res://Scenes/UI/MainMenu.tscn")

func _on_save_pressed() -> void:
	if has_node("Btn_snd"):
		$Btn_snd.play()
	else:
		_play_hover_sound()
	GameData.save_game()
	save_btn.text = "¡Partida Guardada!"
	var t = create_tween()
	t.tween_interval(2.0)
	t.tween_callback(func(): save_btn.text = "Guardar partida")

func _on_quit_pressed() -> void:
	get_tree().quit()

# ahora controla el bus de música en vez del Master general
func _on_volume_changed(value: float) -> void:
	_apply_bus_volume("Music", value)
	_update_volume_labels()

# slider nuevo para el volumen de efectos, en su propio bus
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

func _setup_volume_sliders() -> void:
	for slider in [volume_slider, sfx_slider]:
		slider.min_value = 0.0
		slider.max_value = 100.0
		slider.step = 5.0
		slider.custom_minimum_size.y = 32.0 # mas alto, para que sea facil de agarrar
		slider.focus_mode = Control.FOCUS_NONE # asi las teclas del juego no lo mueven sin querer

func _update_volume_labels() -> void:
	volume_label.text = "Música: %d%%" % int(volume_slider.value)
	sfx_label.text = "Efectos: %d%%" % int(sfx_slider.value)

# Los valores viven en GameSettings (se comparten con la pantalla de opciones del menu principal)
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
	# Curva al cuadrado: el oido percibe el volumen de forma logaritmica, asi el 50% suena
	# realmente a la mitad (-12 dB) en vez de casi igual que el 100% (-6 dB con la recta).
	var t = value / 100.0
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(t * t))
