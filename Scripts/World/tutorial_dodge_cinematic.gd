extends Node2D
## Un disparo dirigido: el tiempo de lectura nunca consume la ventana de evasión.
signal completed

var player: Node2D
var shooter: Node2D
var camera: Camera2D
var previous_camera: Camera2D
var overlay: CanvasLayer
var prompt: Label
var bullet: Sprite2D
var elapsed := 0.0
var stage := -1
var transition: ColorRect
var head_prompt: TutorialInputIcon
var intro_tween: Tween
var slow_audio: AudioStreamPlayer
var released := false
var restored := false
var hidden_layers: Array[CanvasLayer] = []
var previous_scale := 1.0
var previous_mode := Node.PROCESS_MODE_INHERIT
var body_disable_mode := 0
var sprite_mode := Node.PROCESS_MODE_INHERIT
var shooter_mode := Node.PROCESS_MODE_INHERIT
var shooter_sprite_mode := Node.PROCESS_MODE_INHERIT
var shooter_position := Vector2.ZERO
var previous_position := Vector2.ZERO

# Sonidos de la cámara lenta: entra (el tiempo se frena), zumbido mientras dura,
# la bala que pasa lenta y la salida cuando se esquiva.
const SFX_SLOWMO_IN := preload("res://Audio/Sfx/IA/slowmo_entrada.wav")
const SFX_SLOWMO_LOOP := preload("res://Audio/Sfx/IA/slowmo_ambiente.ogg")
const SFX_SLOWMO_OUT := preload("res://Audio/Sfx/IA/slowmo_salida.wav")
const SFX_SLOWMO_BULLET := preload("res://Audio/Sfx/IA/slowmo_bala.wav")
var slowmo_loop: AudioStreamPlayer
# Tecla o botón del dash al lado del texto (ESPACIO con teclado, A con joystick)
var prompt_row: HBoxContainer
var key_icon: Control
var key_icon_pad := false

# Sonidos de la cámara lenta: entra (el tiempo se frena), zumbido mientras dura,
# la bala que pasa lenta y la salida cuando se esquiva.
const SFX_SLOWMO_IN := preload("res://Audio/Sfx/IA/slowmo_entrada.wav")
const SFX_SLOWMO_LOOP := preload("res://Audio/Sfx/IA/slowmo_ambiente.ogg")
const SFX_SLOWMO_OUT := preload("res://Audio/Sfx/IA/slowmo_salida.wav")
const SFX_SLOWMO_BULLET := preload("res://Audio/Sfx/IA/slowmo_bala.wav")
var slowmo_loop: AudioStreamPlayer
# Tecla o botón del dash al lado del texto (ESPACIO con teclado, A con joystick)
var prompt_row: HBoxContainer
var key_icon: Control
var key_icon_pad := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	previous_scale = Engine.time_scale
	previous_mode = player.process_mode
	body_disable_mode = player.disable_mode
	player.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	previous_position = player.global_position
	previous_camera = get_viewport().get_camera_2d()
	sprite_mode = player.anim_sprite.process_mode
	player.anim_sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	player.freeze_player()
	player.process_mode = Node.PROCESS_MODE_DISABLED
	shooter_mode = shooter.process_mode
	shooter_sprite_mode = shooter.anim_sprite.process_mode
	shooter_position = shooter.global_position
	shooter.process_mode = Node.PROCESS_MODE_DISABLED
	_hide_hud(get_tree().root)
	_build_overlay()
	_play_cinematic_sound(preload("res://Audio/Dash_sound.wav"), -10.0, 0.65)
	intro_tween = create_tween().set_ignore_time_scale(true)
	intro_tween.tween_property(transition, "color:a", 1.0, 0.25)
	intro_tween.tween_callback(_stage_scene)
	intro_tween.tween_property(transition, "color:a", 0.0, 0.45)
	intro_tween.tween_callback(func():
		stage = 0
		elapsed = 0.0)

func _stage_scene() -> void:
	# El corredor inferior de esta sala está libre de jardineras y estaciones.
	player.global_position = Vector2(-210, -40)
	player.last_dir = "right"
	player.anim_sprite.play("idle_right")
	player.update_glock()
	shooter.velocity = Vector2.ZERO
	shooter.process_mode = Node.PROCESS_MODE_DISABLED
	shooter.global_position = Vector2(-30, -40)
	shooter.get_node("Summon_anim").hide()
	shooter.anim_sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	shooter.anim_sprite.play("idle")
	shooter.anim_sprite.flip_h = true
	camera = Camera2D.new()
	add_child(camera)
	camera.global_position = Vector2(-120, -40)
	camera.zoom = Vector2.ONE * minf(3.2, get_viewport_rect().size.x / 290.0)
	camera.make_current()
	var push_in := create_tween().set_ignore_time_scale(true)
	push_in.tween_property(camera, "zoom", camera.zoom * 1.08, 1.8).set_trans(Tween.TRANS_SINE)
	Engine.time_scale = 0.12
<<<<<<< HEAD
	var heartbeat := preload("res://Audio/Sfx/Low_health_heartbeat.wav").duplicate() as AudioStreamWAV
	heartbeat.loop_begin = 0
	heartbeat.loop_end = int(heartbeat.get_length() * heartbeat.mix_rate)
	heartbeat.loop_mode = AudioStreamWAV.LOOP_FORWARD
	slow_audio = _play_cinematic_sound(heartbeat, -22.0, 0.75)
	slow_audio.volume_db = -40.0
	var audio_fade := create_tween().set_ignore_time_scale(true)
	audio_fade.tween_property(slow_audio, "volume_db", -22.0, 0.6)

func _play_cinematic_sound(stream: AudioStream, volume: float, pitch := 1.0) -> AudioStreamPlayer:
	var sound := AudioStreamPlayer.new()
	sound.stream = stream
	sound.bus = "SFX"
	sound.volume_db = volume
	sound.pitch_scale = pitch
	add_child(sound)
	sound.play()
	sound.finished.connect(sound.queue_free)
	return sound
=======
	_play_sfx(SFX_SLOWMO_IN, 0.0)
	var loop_stream: AudioStream = SFX_SLOWMO_LOOP
	loop_stream.set("loop", true) # el zumbido se repite hasta que se esquiva
	slowmo_loop = _play_sfx(loop_stream, -6.0)

# El sonido sigue aunque el juego esté en cámara lenta (no depende de time_scale).
func _play_sfx(stream: AudioStream, volume_db: float, keep_after_free := false) -> AudioStreamPlayer:
	var sfx := AudioStreamPlayer.new()
	sfx.stream = stream
	sfx.bus = "SFX"
	sfx.volume_db = volume_db
	sfx.process_mode = Node.PROCESS_MODE_ALWAYS
	if keep_after_free:
		get_tree().root.add_child(sfx) # la cinemática se borra antes de que termine
		sfx.finished.connect(sfx.queue_free)
	else:
		add_child(sfx)
	sfx.play()
	return sfx

func _stop_slowmo_loop() -> void:
	if is_instance_valid(slowmo_loop):
		slowmo_loop.stop()
>>>>>>> 7cfea6efeb3b6ec6882ad69f4ca800ef32419be9

func _hide_hud(node: Node) -> void:
	if node is CanvasLayer and node.visible:
		hidden_layers.append(node)
		node.hide()
	for child in node.get_children():
		_hide_hud(child)

func _build_overlay() -> void:
	overlay = CanvasLayer.new()
	overlay.layer = 110
	add_child(overlay)
	for bottom in [false, true]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(bar)
		bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE if bottom else Control.PRESET_TOP_WIDE)
		bar.offset_top = -65 if bottom else 0
		bar.offset_bottom = 0 if bottom else 65
	prompt_row = HBoxContainer.new()
	prompt_row.alignment = BoxContainer.ALIGNMENT_CENTER
	prompt_row.add_theme_constant_override("separation", 16)
	prompt_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(prompt_row)
	prompt_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	prompt_row.offset_top = -62
	prompt_row.offset_bottom = -8
	prompt_row = HBoxContainer.new()
	prompt_row.alignment = BoxContainer.ALIGNMENT_CENTER
	prompt_row.add_theme_constant_override("separation", 16)
	prompt_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(prompt_row)
	prompt_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	prompt_row.offset_top = -62
	prompt_row.offset_bottom = -8
	prompt = Label.new()
	prompt_row.add_child(prompt)
	prompt_row.add_child(prompt)
	prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
<<<<<<< HEAD
	prompt.add_theme_font_size_override("font_size", 24)
	prompt.text = ""
	head_prompt = TutorialInputIcon.create("SHIFT", 1.15)
	head_prompt.size = head_prompt.custom_minimum_size
	head_prompt.set_process(false) # Animación en tiempo real durante el slow motion.
	head_prompt.hide()
	overlay.add_child(head_prompt)
	transition = ColorRect.new()
	transition.color = Color(0, 0, 0, 0)
	transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(transition)
	transition.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
=======
	prompt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	prompt.add_theme_font_size_override("font_size", 26)
	prompt.text = "OBSERVA EL DISPARO"
>>>>>>> 7cfea6efeb3b6ec6882ad69f4ca800ef32419be9

# Muestra la tecla (o el botón del joystick) del dash delante del texto.
func _show_dash_key() -> void:
	var pad := InputMode.is_gamepad()
	if is_instance_valid(key_icon) and key_icon_pad == pad: return
	if is_instance_valid(key_icon): key_icon.queue_free()
	key_icon_pad = pad
	key_icon = TutorialInputIcon.create("ESPACIO", 0.8)
	prompt_row.add_child(key_icon)
	prompt_row.move_child(key_icon, 0)

func _hide_dash_key() -> void:
	if is_instance_valid(key_icon): key_icon.queue_free()

func _input(event: InputEvent) -> void:
	if restored: return
	if stage == 2 and released and not event.is_echo():
<<<<<<< HEAD
		var keyboard: bool = event is InputEventKey and event.pressed and event.keycode in [KEY_SHIFT, KEY_SPACE]
		var gamepad: bool = event is InputEventJoypadButton and event.is_action_pressed("dash")
		if keyboard or gamepad:
=======
		# la acción "dash" ya incluye Espacio, Shift y la A del joystick
		if event.is_action_pressed("dash"):
>>>>>>> 7cfea6efeb3b6ec6882ad69f4ca800ef32419be9
			stage = 3
			elapsed = 0.0
			head_prompt.hide()
			_play_cinematic_sound(preload("res://Audio/Dash_sound.wav"), -6.0, 1.15)
			if is_instance_valid(slow_audio):
				var fade := create_tween().set_ignore_time_scale(true)
				fade.tween_property(slow_audio, "volume_db", -45.0, 0.35)
			player.velocity = Vector2.DOWN
			player._start_dash()
			player.dash_dir = Vector2.DOWN
			prompt.text = "¡EVASIÓN PERFECTA!"
			_hide_dash_key()
			_stop_slowmo_loop()
			_play_sfx(SFX_SLOWMO_OUT, 0.0, true)
			_hide_dash_key()
			_stop_slowmo_loop()
			_play_sfx(SFX_SLOWMO_OUT, 0.0, true)
			prompt.modulate = Color(0.3, 1.0, 0.8)
	get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if restored: return
	if not is_instance_valid(player):
		restore()
		queue_free()
		return
	var real_delta := delta / maxf(Engine.time_scale, 0.001)
	elapsed += real_delta
	if not Input.is_action_pressed("dash") and not Input.is_key_pressed(KEY_SHIFT):
		released = true
	match stage:
		0:
			if elapsed >= 0.65:
				shooter.anim_sprite.play("attack_side")
				# El tirador está desactivado: el audio vive en la cinemática.
				_play_cinematic_sound(preload("res://Audio/Enemy_snd/Enemy_range_shoot.mp3"), -5.0, 0.85)
				bullet = Sprite2D.new()
				bullet.texture = preload("res://Art/Weapons/Distance/Pistol/enemyprojectile16x6.png")
				bullet.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				bullet.rotation = PI
				add_child(bullet)
				bullet.global_position = shooter.global_position + Vector2(-18, 0)
				_play_sfx(SFX_SLOWMO_BULLET, -2.0)
				_play_sfx(SFX_SLOWMO_BULLET, -2.0)
				stage = 1
				elapsed = 0.0
		1:
			bullet.position.x -= 500.0 * delta
			if bullet.global_position.x <= player.global_position.x + 55.0:
				stage = 2
				elapsed = 0.0
				head_prompt.show()
		2:
<<<<<<< HEAD
			head_prompt.key = "ESPACIO" if InputMode.is_gamepad() else "SHIFT"
			head_prompt.position = player.get_global_transform_with_canvas().origin - Vector2(head_prompt.size.x * 0.5, 110.0 + head_prompt.size.y)
			head_prompt.position.y += sin(elapsed * 5.0) * 5.0
			head_prompt._process(real_delta)
			prompt.text = "PULSA EL BOTÓN DE EVASIÓN" if InputMode.is_gamepad() else "PULSA SHIFT O ESPACIO PARA EVADIR"
=======
			_show_dash_key()
			prompt.text = "PARA ESQUIVAR CON EL DASH" if InputMode.is_gamepad() else "O SHIFT PARA ESQUIVAR CON EL DASH"
>>>>>>> 7cfea6efeb3b6ec6882ad69f4ca800ef32419be9
			prompt.modulate = Color(1.0, 0.85 + sin(elapsed * 5.0) * 0.15, 0.4)
		3:
			# Movimiento dirigido con colisión real; no admite disparos ni movimiento libre.
			if elapsed < 0.3:
				player.move_and_collide(Vector2.DOWN * 150.0 * real_delta)
				player._process_dash_ghosts(real_delta)
			bullet.position.x -= 420.0 * real_delta
			if elapsed >= 0.8:
				restore(false)
				completed.emit()
				queue_free()

func restore(cancelled := true) -> void:
	if restored: return
	restored = true
	if intro_tween and intro_tween.is_valid(): intro_tween.kill()
	for child in get_children():
		if child is AudioStreamPlayer: child.stop()
	Engine.time_scale = previous_scale
	_stop_slowmo_loop()
	_stop_slowmo_loop()
	for layer in hidden_layers:
		if is_instance_valid(layer): layer.show()
	hidden_layers.clear()
	if is_instance_valid(shooter):
		shooter.anim_sprite.process_mode = shooter_sprite_mode
		shooter.process_mode = shooter_mode
		if cancelled: shooter.global_position = shooter_position
	if is_instance_valid(player):
		if player.is_dashing:
			player.dash_timer.stop()
			player._on_dash_timer_timeout()
		player.dash_cd_timer.stop()
		if cancelled: player.global_position = previous_position
		player.anim_sprite.process_mode = sprite_mode
		player.unfreeze_player()
		player.process_mode = previous_mode
		player.disable_mode = body_disable_mode
	if is_instance_valid(previous_camera) and previous_camera.is_inside_tree() and previous_camera.enabled:
		previous_camera.make_current()
	if is_instance_valid(overlay): overlay.hide()

func _exit_tree() -> void:
	restore()
