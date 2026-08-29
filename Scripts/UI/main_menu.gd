extends Control

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var continue_button: Button = $VBoxContainer/PlayButton2
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton
@onready var button_group: VBoxContainer = $VBoxContainer # Referencia para animar el menú.

func _ready():
	play_button.pressed.connect(_on_play_pressed)
	if continue_button: continue_button.pressed.connect(_on_continue_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	if has_node("Btn_snd"): $Btn_snd.bus = "SFX"
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if continue_button:
		var last_slot = GameData.get_last_played_slot()
		var info = GameData.get_slot_info(last_slot)
		if info.exists:
			continue_button.disabled = false
		else:
			continue_button.disabled = true
	
	_play_intro_animation() # Entrada prolija del menú (antes aparecía de golpe).

# Animación de aparición: fade + leve escala desde el centro del bloque de botones.
func _play_intro_animation() -> void:
	await get_tree().process_frame
	button_group.pivot_offset = button_group.size / 2.0
	button_group.modulate.a = 0.0
	button_group.scale = Vector2(0.92, 0.92)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(button_group, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(button_group, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_play_pressed():
	$Btn_snd.play()
	_play_exit_animation(func(): SceneTransition.change_scene("res://Scenes/UI/newgame.tscn"))

func _on_continue_pressed():
	$Btn_snd.play()
	var last_slot = GameData.get_last_played_slot()
	if GameData.load_game(last_slot):
		_play_exit_animation(func(): SceneTransition.change_scene("res://Scenes/Rooms/lab_room.tscn"))

func _on_options_pressed():
	$Btn_snd.play()
	OptionsMenu.open()

func _on_exit_pressed():
	# Cierra el juego
	$Btn_snd.play()
	_play_exit_animation(func(): get_tree().quit())

# Animación de salida antes de cambiar de escena o cerrar el juego, para que no corte seco.
func _play_exit_animation(on_finished: Callable) -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(button_group, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(button_group, "scale", Vector2(0.92, 0.92), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(on_finished)
