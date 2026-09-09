extends CanvasLayer

var color_rect: ColorRect
var is_transitioning: bool = false
var mainmenu_music: AudioStreamPlayer
var combat_music: AudioStreamPlayer
var level2_music: AudioStreamPlayer
var teleport_sfx: AudioStreamPlayer

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
	mainmenu_music.bus = "Music" # esta es la música que realmente suena en el menú, tenía que ir en su propio bus
	add_child(mainmenu_music)

	combat_music = AudioStreamPlayer.new()
	combat_music.stream = preload("res://Audio/Music/Ost-Batalla.ogg")
	combat_music.volume_db = -5.0
	combat_music.bus = "Music"
	add_child(combat_music)

	# Placeholder pedido por Marcos: la zona 2 (Level2_Room*) usa por ahora la musica
	# de la fase 2 del boss, hasta que tengamos un tema propio para esa zona.
	level2_music = AudioStreamPlayer.new()
	level2_music.stream = preload("res://Audio/Music/BossFight2.ogg")
	level2_music.volume_db = -5.0
	level2_music.bus = "Music"
	add_child(level2_music)

	teleport_sfx = AudioStreamPlayer.new()
	teleport_sfx.stream = preload("res://Audio/Sfx/Teleport/Teleport.wav")
	teleport_sfx.bus = "SFX"
	add_child(teleport_sfx)
	
	_setup_loops()
	_setup_audio_effects()
	
	# Manejar música inicial basada en la escena actual
	_handle_scene_music(get_tree().current_scene.scene_file_path)

var music_lpf: AudioEffectLowPassFilter = null
var music_eq: AudioEffectEQ6 = null
var _adaptive_music_tween: Tween = null
var _is_in_combat_mode: bool = true

func _setup_audio_effects() -> void:
	var music_bus_idx = AudioServer.get_bus_index("Music")
	if music_bus_idx == -1: return
	music_lpf = _find_or_create_lpf(music_bus_idx)
	music_eq = _find_or_create_eq(music_bus_idx)

func _find_or_create_lpf(bus_idx: int) -> AudioEffectLowPassFilter:
	var count = AudioServer.get_bus_effect_count(bus_idx)
	for i in range(count):
		var effect = AudioServer.get_bus_effect(bus_idx, i)
		if effect is AudioEffectLowPassFilter:
			return effect as AudioEffectLowPassFilter
	var new_lpf = AudioEffectLowPassFilter.new()
	new_lpf.cutoff_hz = 20500.0
	new_lpf.resonance = 0.5
	new_lpf.db = AudioEffectFilter.FILTER_12DB
	AudioServer.add_bus_effect(bus_idx, new_lpf)
	return new_lpf

func _find_or_create_eq(bus_idx: int) -> AudioEffectEQ6:
	var count = AudioServer.get_bus_effect_count(bus_idx)
	for i in range(count):
		var effect = AudioServer.get_bus_effect(bus_idx, i)
		if effect is AudioEffectEQ6:
			return effect as AudioEffectEQ6
	var new_eq = AudioEffectEQ6.new()
	AudioServer.add_bus_effect(bus_idx, new_eq)
	return new_eq

func set_combat_mode(in_combat: bool, immediate: bool = false) -> void:
	if _is_in_combat_mode == in_combat and not immediate: return
	_is_in_combat_mode = in_combat
	
	if _adaptive_music_tween and _adaptive_music_tween.is_valid():
		_adaptive_music_tween.kill()
		
	if immediate:
		_apply_immediate_music_state(in_combat)
		return
		
	_tween_music_state(in_combat)

func _apply_immediate_music_state(in_combat: bool) -> void:
	var target_cutoff = 20500.0 if in_combat else 850.0
	var target_vol = -5.0 if in_combat else -9.0
	var kick_gain = 3.5 if in_combat else -1.5
	var snare_gain = 2.5 if in_combat else -2.0
	var snap_gain = 1.5 if in_combat else -2.5
	
	_set_music_cutoff(target_cutoff)
	_set_music_volume(target_vol)
	_set_eq_gains(kick_gain, snare_gain, snap_gain)

func _set_music_cutoff(cutoff: float) -> void:
	if not music_lpf: return
	music_lpf.cutoff_hz = cutoff

func _set_music_volume(vol_db: float) -> void:
	if combat_music: combat_music.volume_db = vol_db
	if level2_music: level2_music.volume_db = vol_db

func _set_eq_gains(kick: float, snare: float, snap: float) -> void:
	if not music_eq: return
	music_eq.set_band_gain_db(1, kick)
	music_eq.set_band_gain_db(2, snare)
	music_eq.set_band_gain_db(4, snap)

func _tween_music_state(in_combat: bool) -> void:
	var duration = 0.85 if in_combat else 1.6
	var trans = Tween.TRANS_QUAD if in_combat else Tween.TRANS_SINE
	var target_cutoff = 20500.0 if in_combat else 850.0
	var target_vol = -5.0 if in_combat else -9.0
	var kick_gain = 3.5 if in_combat else -1.5
	var snare_gain = 2.5 if in_combat else -2.0
	var snap_gain = 1.5 if in_combat else -2.5
	
	_adaptive_music_tween = create_tween().set_parallel(true)
	_tween_cutoff(_adaptive_music_tween, target_cutoff, duration, trans)
	_tween_volume(_adaptive_music_tween, target_vol, duration, trans)
	_tween_eq(_adaptive_music_tween, kick_gain, snare_gain, snap_gain, duration, trans)

func _tween_cutoff(t: Tween, target_cutoff: float, duration: float, trans: Tween.TransitionType) -> void:
	if not music_lpf: return
	t.tween_property(music_lpf, "cutoff_hz", target_cutoff, duration).set_trans(trans).set_ease(Tween.EASE_OUT)

func _tween_volume(t: Tween, target_vol: float, duration: float, trans: Tween.TransitionType) -> void:
	if combat_music:
		t.tween_property(combat_music, "volume_db", target_vol, duration).set_trans(trans).set_ease(Tween.EASE_OUT)
	if level2_music:
		t.tween_property(level2_music, "volume_db", target_vol, duration).set_trans(trans).set_ease(Tween.EASE_OUT)

func _tween_eq(t: Tween, kick: float, snare: float, snap: float, duration: float, trans: Tween.TransitionType) -> void:
	if not music_eq: return
	t.tween_method(_tween_eq_band.bind(1), music_eq.get_band_gain_db(1), kick, duration).set_trans(trans).set_ease(Tween.EASE_OUT)
	t.tween_method(_tween_eq_band.bind(2), music_eq.get_band_gain_db(2), snare, duration).set_trans(trans).set_ease(Tween.EASE_OUT)
	t.tween_method(_tween_eq_band.bind(4), music_eq.get_band_gain_db(4), snap, duration).set_trans(trans).set_ease(Tween.EASE_OUT)

func _tween_eq_band(val: float, band: int) -> void:
	if not music_eq: return
	music_eq.set_band_gain_db(band, val)

func _setup_loops() -> void:
	_set_stream_loop(mainmenu_music)
	_set_stream_loop(combat_music)
	_set_stream_loop(level2_music)

func _set_stream_loop(player: AudioStreamPlayer) -> void:
	if not player:
		return
	if not player.stream:
		return
	player.stream.loop = true

func play_teleport_sound() -> void:
	if teleport_sfx:
		teleport_sfx.play()

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

func play_level2_music() -> void:
	if mainmenu_music.playing:
		mainmenu_music.stop()
	if combat_music.playing:
		combat_music.stop()
	if not level2_music.playing:
		level2_music.play()

func stop_level2_music() -> void:
	if level2_music.playing:
		level2_music.stop()

func _handle_scene_music(path: String) -> void:
	var scene_name = path.get_file().to_lower()
	
	if "mainmenu" in scene_name or "newgame" in scene_name:
		play_main_music()
		stop_combat_music()
		stop_level2_music()
	elif "ygor" in scene_name or "lab_room" in scene_name or "debug_scene" in scene_name:
		stop_main_music()
		stop_combat_music()
		stop_level2_music()
	elif "bossfight" in scene_name or "boss_fight" in scene_name:
		stop_main_music()
		stop_combat_music()
		stop_level2_music()
	elif "level2_room" in scene_name:
		play_level2_music()
		stop_main_music()
	elif "level1_room" in scene_name:
		play_combat_music()
		stop_main_music()
		stop_level2_music()

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
