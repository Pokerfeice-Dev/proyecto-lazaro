extends CanvasLayer

@onready var menu_control: Control = $MenuControl
@onready var volume_slider: HSlider = $MenuControl/VBoxContainer/VolumeSlider
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
	$MenuControl/VBoxContainer.move_child(save_btn, 3) # After CloseButton
	
	_bind_buttons(get_tree().root)
	
	self.visible = false

func _init_audio() -> void:
	hover_audio = AudioStreamPlayer.new()
	hover_audio.stream = hover_stream
	hover_audio.bus = "Master"
	add_child(hover_audio)

func _connect_signals() -> void:
	volume_slider.value_changed.connect(_on_volume_changed)
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
	var tween = create_tween()
	tween.tween_property(menu_control, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close() -> void:
	if not is_open: return
	is_open = false
	var tween = create_tween()
	tween.tween_property(menu_control, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
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

func _on_volume_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index("Master")
	if value <= 0:
		AudioServer.set_bus_mute(bus_index, true)
		return
	
	AudioServer.set_bus_mute(bus_index, false)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value / 100.0))
