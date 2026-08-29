extends CanvasLayer

@onready var menu_control: Control = $MenuControl
@onready var volume_slider: HSlider = $MenuControl/VBoxContainer/VolumeSlider
@onready var sfx_slider: HSlider = $MenuControl/VBoxContainer/SfxSlider
@onready var close_btn: Button = $MenuControl/VBoxContainer/CloseButton
@onready var menu_btn: Button = $MenuControl/VBoxContainer/MenuButton
@onready var quit_btn: Button = $MenuControl/VBoxContainer/QuitButton

var hover_audio: AudioStreamPlayer
var hover_stream = preload("res://Audio/Sfx/Piano_Ui (2).wav")

var is_open: bool = false
var was_paused: bool = false
var save_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_init_audio()
	_connect_signals()
	
	get_tree().node_added.connect(_on_node_added)
	
	save_btn = Button.new()
	save_btn.text = "Guardar partida"
	save_btn.pressed.connect(_on_save_pressed)
	$MenuControl/VBoxContainer.add_child(save_btn)
	# se calcula el índice en vez de un número fijo, para no depender del orden de los demás nodos
	$MenuControl/VBoxContainer.move_child(save_btn, close_btn.get_index() + 1)
	
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
	var tween = create_tween().set_parallel(true) # Fade + scale de salida en paralelo.
	tween.tween_property(menu_control, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(menu_control, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(_on_close_finished)

func _on_close_finished() -> void:
	self.visible = false
	if not was_paused:
		get_tree().paused = false

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

# slider nuevo para el volumen de efectos, en su propio bus
func _on_sfx_volume_changed(value: float) -> void:
	_apply_bus_volume("SFX", value)

func _apply_bus_volume(bus_name: String, value: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1: return
	if value <= 0:
		AudioServer.set_bus_mute(bus_index, true)
		return

	AudioServer.set_bus_mute(bus_index, false)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value / 100.0))
