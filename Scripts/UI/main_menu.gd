extends Control

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var continue_button: Button = $VBoxContainer/PlayButton2
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton
@onready var button_group: VBoxContainer = $VBoxContainer # Referencia para animar el menú.
@onready var logo: TextureRect = get_node_or_null("Logo_Franken")
var _atmosphere: Control
var _menu_motion := true
var _parallax := Vector2.ZERO
var _leaving := false
var _button_tweens: Dictionary = {}

func _process(delta: float) -> void:
	var target := Vector2.ZERO
	if _menu_motion and not is_instance_valid(_options_screen) and not _leaving:
		target = (get_local_mouse_position() / size - Vector2(0.5, 0.5)).clamp(Vector2(-0.5, -0.5), Vector2(0.5, 0.5))
	_parallax = _parallax.lerp(target, 1.0 - exp(-delta * 3.0))
	for node_name in ["Background", "Barrotes"]:
		var plane = get_node_or_null(node_name) as Control
		if plane:
			plane.pivot_offset = plane.size / 2.0
			plane.scale = Vector2.ONE * 1.035
			plane.position = _parallax * (-12.0 if node_name == "Background" else -24.0)

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
	
	if GameData.show_title_screen:
		_show_title_prompt()
	else:
		_play_intro_animation() # Entrada prolija del menú (antes aparecía de golpe).
	_animate_logo()
	# con el título, los efectos se arman al mostrar los botones: ocultos no
	# tienen tamaño y el brillo del shader quedaba cortado
	if not GameData.show_title_screen:
		_setup_button_fx()
	_apply_menu_settings()
	_atmosphere = preload("res://Scripts/UI/menu_atmosphere.gd").new()
	add_child(_atmosphere)
	move_child(_atmosphere, logo.get_index() if logo else button_group.get_index())
	_atmosphere.motion_enabled = _menu_motion
	_atmosphere.particles_enabled = FxSettings.on("particulas_menu")

# ---- Pantalla de título: los botones aparecen recién al tocar algo ----
var _title_label: Label = null

func _show_title_prompt() -> void:
	button_group.visible = false
	_title_label = UIStyle.label("PRESIONA CUALQUIER BOTÓN", 30, UIStyle.COLOR_GOLD)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title_label)
	await get_tree().process_frame
	_title_label.size.x = maxf(button_group.size.x, _title_label.get_minimum_size().x)
	_title_label.position = button_group.position + Vector2((button_group.size.x - _title_label.size.x) / 2.0, button_group.size.y / 2.0)
	var t = _title_label.create_tween().set_loops()
	t.tween_property(_title_label, "modulate:a", 0.35, 0.8).set_trans(Tween.TRANS_SINE)
	t.tween_property(_title_label, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

func _input(event: InputEvent) -> void:
	if not is_instance_valid(_title_label): return
	var pressed = (event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton) and event.is_pressed() and not event.is_echo()
	if not pressed: return
	get_viewport().set_input_as_handled()
	GameData.show_title_screen = false
	_title_label.queue_free()
	_title_label = null
	if has_node("Btn_snd"): $Btn_snd.play()
	button_group.visible = true
	await get_tree().process_frame # que el contenedor acomode los botones antes de animarlos
	_play_intro_animation()
	_setup_button_fx() # ya con los botones visibles y acomodados (incluye la cascada)

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

# Abre la pantalla de opciones con pestañas (ya no el menu de pausa del juego)
const OPTIONS_SCREEN = preload("res://Scenes/UI/options_screen.tscn")
var _options_screen: Node = null

func _on_options_pressed():
	$Btn_snd.play()
	if is_instance_valid(_options_screen): return
	_options_screen = OPTIONS_SCREEN.instantiate()
	add_child(_options_screen)

# ---- opciones que afectan al menu (lluvia/nieve y fondo animado) ----
var _fondo_material: Material = null

func _apply_menu_settings() -> void:
	if has_node("Background"): _fondo_material = $Background.material
	_set_menu_particles(FxSettings.on("particulas_menu"))
	_set_menu_background_anim(FxSettings.on("fondo_animado_menu"))
	var gs = FxSettings.instance()
	if gs: gs.setting_changed.connect(_on_setting_changed)

func _on_setting_changed(_section: String, key: String, value: Variant) -> void:
	match key:
		"particulas_menu": _set_menu_particles(bool(value))
		"fondo_animado_menu": _set_menu_background_anim(bool(value))

func _set_menu_particles(enabled: bool) -> void:
	if is_instance_valid(_atmosphere): _atmosphere.particles_enabled = enabled
	for n in ["RainParticles", "SnowParticles"]:
		var p = get_node_or_null(n)
		if not p: continue
		p.visible = enabled
		p.emitting = enabled

# sin el material, Lazaro queda quieto (la imagen es la misma, solo deja de respirar)
func _set_menu_background_anim(enabled: bool) -> void:
	_menu_motion = enabled
	if is_instance_valid(_atmosphere): _atmosphere.motion_enabled = enabled
	if not has_node("Background"): return
	$Background.material = _fondo_material if enabled else null

func _on_exit_pressed():
	# Cierra el juego
	$Btn_snd.play()
	_play_exit_animation(func(): get_tree().quit())

# ---- FX de los botones: entrada en cascada, hover con borde electrico y chispas, click con destello ----
const BOTON_SHADER = preload("res://Art/Menu/Animado/menu_boton.gdshader")
var _botones: Array[Button] = []

func _setup_button_fx() -> void:
	await get_tree().process_frame
	if not _botones.is_empty(): return
	var i = 0
	for child in button_group.get_children():
		if child is Button:
			_botones.append(child)
			_prepare_button(child, i)
			i += 1
	_play_buttons_cascade()

func _prepare_button(btn: Button, index: int) -> void:
	btn.pivot_offset = btn.size / 2.0
	var mat = ShaderMaterial.new()
	mat.shader = BOTON_SHADER
	mat.set_shader_parameter("tam_px", btn.size)
	mat.set_shader_parameter("desfase_brillo", -0.08 * index)
	mat.set_shader_parameter("hover", 0.0)
	mat.set_shader_parameter("flash", 0.0)
	btn.material = mat
	btn.add_child(_create_sparks(btn))
	btn.mouse_entered.connect(_on_button_hover.bind(btn, true))
	btn.mouse_exited.connect(_on_button_hover.bind(btn, false))
	btn.focus_entered.connect(_on_button_hover.bind(btn, true))
	btn.focus_exited.connect(_on_button_hover.bind(btn, false))
	btn.button_down.connect(_on_button_down.bind(btn))
	btn.button_up.connect(_on_button_up.bind(btn))
	btn.resized.connect(_on_button_resized.bind(btn))

# Después de la pantalla de título los botones se acomodan un cuadro más tarde:
# si el pivote y el shader se quedaban con el tamaño viejo, "Jugar" aparecía
# corrido, más grande y con el brillo cortado.
func _on_button_resized(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	var mat = btn.material as ShaderMaterial
	if mat: mat.set_shader_parameter("tam_px", btn.size)
	var sparks = btn.get_node_or_null("Chispas") as CPUParticles2D
	if sparks:
		sparks.position = btn.size / 2.0
		sparks.emission_rect_extents = btn.size / 2.0

func _create_sparks(btn: Button) -> CPUParticles2D:
	var p = CPUParticles2D.new()
	p.name = "Chispas"
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 16
	p.lifetime = 0.45
	p.position = btn.size / 2.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = btn.size / 2.0
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, 120)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 160.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	var grad = Gradient.new()
	grad.set_color(0, Color(0.7, 1.0, 0.95, 1.0))
	grad.set_color(1, Color(0.3, 0.9, 1.0, 0.0))
	p.color_ramp = grad
	return p

# los botones aparecen uno atras del otro, con un pequeño rebote
func _play_buttons_cascade() -> void:
	for i in _botones.size():
		var btn = _botones[i]
		btn.scale = Vector2(0.6, 0.6)
		btn.modulate.a = 0.0
		var t = create_tween().set_parallel(true)
		t.tween_property(btn, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.25 + i * 0.09)
		t.tween_property(btn, "modulate:a", 1.0 if not btn.disabled else 0.55, 0.3).set_delay(0.25 + i * 0.09)

func _on_button_hover(btn: Button, entered: bool) -> void:
	if btn.disabled or _leaving: return
	entered = btn.is_hovered() or btn.has_focus()
	if _button_tweens.has(btn) and _button_tweens[btn].is_valid():
		_button_tweens[btn].kill()
	var mat = btn.material as ShaderMaterial
	var t = create_tween().set_parallel(true)
	_button_tweens[btn] = t
	t.tween_property(btn, "scale", Vector2(1.07, 1.07) if entered else Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(btn, "rotation_degrees", randf_range(-1.2, 1.2) if entered else 0.0, 0.18)
	if mat:
		var desde = mat.get_shader_parameter("hover")
		if desde == null: desde = 0.0
		t.tween_method(_set_shader_param.bind(mat, "hover"), desde, 1.0 if entered else 0.0, 0.2)
	if entered:
		_burst_sparks(btn, 16)

func _on_button_down(btn: Button) -> void:
	if btn.disabled: return
	if is_instance_valid(_atmosphere): _atmosphere.surge()
	var mat = btn.material as ShaderMaterial
	var t = create_tween().set_parallel(true)
	t.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.06)
	if mat:
		t.tween_method(_set_shader_param.bind(mat, "flash"), 1.0, 0.0, 0.35)
	_burst_sparks(btn, 40)
	_shake_menu()

func _on_button_up(btn: Button) -> void:
	if btn.disabled: return
	create_tween().tween_property(btn, "scale", Vector2(1.07, 1.07), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _burst_sparks(btn: Button, amount: int) -> void:
	if not FxSettings.on("particulas_menu"): return
	var p = btn.get_node_or_null("Chispas") as CPUParticles2D
	if not p: return
	p.amount = amount
	p.restart()
	p.emitting = true

# sacudon chiquito de toda la columna de botones al hacer click
func _shake_menu() -> void:
	var base = button_group.position
	var t = create_tween()
	for k in 4:
		t.tween_property(button_group, "position", base + Vector2(randf_range(-5, 5), randf_range(-3, 3)), 0.03)
	t.tween_property(button_group, "position", base, 0.04)

func _set_shader_param(value: float, mat: ShaderMaterial, param: String) -> void:
	mat.set_shader_parameter(param, value)

# El logo flota y respira apenas (mismo ritmo que la respiracion de Lazaro en el fondo)
# y cada tanto tiene un chispazo de energia, bien Frankenstein.
func _animate_logo() -> void:
	if not logo: return
	await get_tree().process_frame
	logo.pivot_offset = logo.size / 2.0
	_start_logo_float()
	_start_logo_breath()
	_start_logo_sparks()

func _start_logo_float() -> void:
	var base_y = logo.position.y
	var t = create_tween().set_loops()
	t.tween_property(logo, "position:y", base_y - 6.0, 2.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(logo, "position:y", base_y, 2.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _start_logo_breath() -> void:
	var t = create_tween().set_loops()
	t.tween_property(logo, "scale", Vector2(1.012, 1.012), 2.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(logo, "scale", Vector2.ONE, 2.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _start_logo_sparks() -> void:
	var timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(_on_logo_spark_timer.bind(timer))
	timer.start(randf_range(4.0, 7.0))

func _on_logo_spark_timer(timer: Timer) -> void:
	var t = create_tween()
	t.tween_property(logo, "modulate", Color(1.35, 1.35, 1.5), 0.05)
	t.tween_property(logo, "modulate", Color.WHITE, 0.08)
	t.tween_property(logo, "modulate", Color(1.2, 1.2, 1.35), 0.04)
	t.tween_property(logo, "modulate", Color.WHITE, 0.25)
	timer.start(randf_range(6.0, 10.0))

# Animación de salida antes de cambiar de escena o cerrar el juego, para que no corte seco.
func _play_exit_animation(on_finished: Callable) -> void:
	if _leaving: return
	_leaving = true
	for btn in _botones: btn.disabled = true
	var tween = create_tween().set_parallel(true)
	tween.tween_property(button_group, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(button_group, "scale", Vector2(0.92, 0.92), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(on_finished)
