extends Control

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var continue_button: Button = $VBoxContainer/PlayButton2
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton

func _ready():
	play_button.pressed.connect(_on_play_pressed)
	if continue_button: continue_button.pressed.connect(_on_continue_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if continue_button:
		var last_slot = GameData.get_last_played_slot()
		var info = GameData.get_slot_info(last_slot)
		if info.exists:
			continue_button.disabled = false
		else:
			continue_button.disabled = true

func _on_play_pressed():
	$Btn_snd.play()
	SceneTransition.change_scene("res://Scenes/UI/newgame.tscn")

func _on_continue_pressed():
	$Btn_snd.play()
	var last_slot = GameData.get_last_played_slot()
	if GameData.load_game(last_slot):
		SceneTransition.change_scene("res://Scenes/Rooms/lab_room.tscn")

func _on_options_pressed():
	$Btn_snd.play()
	OptionsMenu.open()

func _on_exit_pressed():
	# Cierra el juego
	$Btn_snd.play()
	get_tree().quit()
