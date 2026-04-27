extends CanvasLayer

var color_rect: ColorRect
var is_transitioning: bool = false
var mainmenu_music: AudioStreamPlayer
var combat_music: AudioStreamPlayer

func _ready():
	layer = 120 # Aseguramos que se superponga por encima de cualquier otro CanvasLayer u objeto HUD.
	
	color_rect = ColorRect.new()
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)
	
	var cursor = load("res://Art/Mouse/Shoot_sight.png")
	if cursor:
		Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, cursor.get_size() / 2)
		
	mainmenu_music = AudioStreamPlayer.new()
	mainmenu_music.stream = preload("res://Audio/Music/sn2.ogg")
	mainmenu_music.volume_db = -3.0
	mainmenu_music.bus = "Master"
	add_child(mainmenu_music)
	
	combat_music = AudioStreamPlayer.new()
	combat_music.stream = preload("res://Audio/Music/sn1.ogg")
	combat_music.volume_db = -5.0
	combat_music.bus = "Master"
	add_child(combat_music)
	
	# Manejar música inicial basada en la escena actual
	_handle_scene_music(get_tree().current_scene.scene_file_path)

func play_main_music() -> void:
	if combat_music.playing:
		combat_music.stop()
	if not mainmenu_music.playing:
		mainmenu_music.play()

func stop_main_music() -> void:
	if mainmenu_music.playing:
		mainmenu_music.stop()

func play_combat_music() -> void:
	if mainmenu_music.playing:
		mainmenu_music.stop()
	if not combat_music.playing:
		combat_music.play()

func stop_combat_music() -> void:
	if combat_music.playing:
		combat_music.stop()

func _handle_scene_music(path: String) -> void:
	var scene_name = path.get_file().to_lower()
	
	if "mainmenu" in scene_name or "newgame" in scene_name:
		play_main_music()
		stop_combat_music()
	elif "room_" in scene_name and not "room_ygor" in scene_name:
		play_combat_music()
		stop_main_music()
	elif "lab_room" in scene_name or "room_ygor" in scene_name:
		stop_main_music()
		stop_combat_music()

func change_scene(path: String) -> void:
	if is_transitioning:
		return
		
	is_transitioning = true
	_handle_scene_music(path)
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP # Evitamos interacciones mientras cambia la escena
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(color_rect, "color", Color(0, 0, 0, 1), 0.5)
	await tween.finished
	
	get_tree().change_scene_to_file(path)
	
	# Esperar un momento a que esté cargada
	await get_tree().create_timer(0.1).timeout
	
	# Fade in
	tween = create_tween()
	tween.tween_property(color_rect, "color", Color(0, 0, 0, 0), 0.5)
	await tween.finished
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false
