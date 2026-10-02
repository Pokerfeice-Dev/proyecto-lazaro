extends EnemyBase
class_name Boss2

## Boss del área 2, estilo "Monstro" (TBoI): un blob que persigue al jugador
## a los saltos (en vez de caminar), se reposiciona/aplasta en área al
## aterrizar, muerde cuerpo a cuerpo cuando está pegado al jugador, escupe
## proyectiles en abanico a distancia, y de vez en cuando invoca mutantes de
## refuerzo. Todavía no hay arte final (Boss2Visual es un placeholder dibujado
## por código -- pendiente de reemplazar por el sprite de slime que bajó
## Marcos), así que la lógica está pensada para no depender de la sala: usa
## la posición donde se lo coloque como "centro" y un rango configurable para
## saber hasta dónde puede saltar.

@export_group("Boss Base Stats")
@export var boss_max_health: int = 1400
@export var boss_damage: int = 22
@export var boss_display_name: String = "??? (nombre pendiente)"

@export_group("Boss Arena")
## Hasta dónde se puede alejar el boss de su posición inicial al saltar.
## Ajustar cuando exista la sala real.
@export var arena_half_extents: Vector2 = Vector2(320, 220)

@export_group("Boss Patterns")
@export var time_between_patterns: float = 3.2
@export var patterns_between_summon_check: int = 4
@export var jump_pattern_chance: float = 0.55

@export_group("Boss Jump Attack")
@export var jump_telegraph_time: float = 0.55
@export var jump_airborne_time: float = 0.45
@export var jump_recover_time: float = 0.4
@export var jump_slam_radius: float = 95.0
@export var jump_slam_damage_mult: float = 1.3
@export var triple_jump_chance: float = 0.35
@export var min_jump_distance_from_player: float = 40.0

@export_group("Boss Spit Attack")
@export var spit_projectile_scene: PackedScene = preload("res://Scenes/Enemies/enemy_shooter_projectile.tscn")
@export var spit_volleys: int = 2
@export var spit_shots_per_volley: int = 3
@export var spit_spread_degrees: float = 30.0
@export var spit_delay_between_volleys: float = 0.5
@export var spit_recover_time: float = 0.5

@export_group("Boss Summon")
@export var minion_scene: PackedScene = preload("res://Scenes/Enemies/EnemyFollower.tscn")
@export var minion_spawn_count: int = 2
@export var summon_recover_time: float = 0.6

@export_group("Boss Chase")
## Debajo de esta distancia no hace falta perseguir (ya está en rango de
## mordida, o casi).
@export var chase_trigger_distance: float = 110.0
## Más allá de esta distancia, el boss usa el salto grande (telegrafiado, con
## sombra y daño de aplastón) para cerrar la brecha de golpe -- tiene lógica
## como "gap closer" cuando te alejaste mucho. Por debajo, se acerca con
## saltitos chicos tipo caminata (ver Boss Walk Hop), sin telegrafiar ni
## hacer daño.
@export var big_jump_distance: float = 480.0
## Distancia que avanza cada salto grande.
@export var chase_hop_distance: float = 150.0
## Cada cuánto se re-evalúa la persecución (saltitos chicos = pasos rápidos y
## seguidos, como una caminata con rebote).
@export var chase_check_interval: float = 0.4

@export_group("Boss Walk Hop")
## Distancia que avanza cada saltito de "caminata" (acercamiento normal, sin
## telegrafiar ni hacer daño -- es solo movimiento).
@export var walk_hop_distance: float = 55.0
@export var walk_hop_telegraph_time: float = 0.1
@export var walk_hop_airborne_time: float = 0.16
@export var walk_hop_recover_time: float = 0.12

@export_group("Boss Melee")
## Distancia a la que el boss puede morder cuerpo a cuerpo.
@export var melee_attack_range: float = 62.0
@export var melee_attack_cooldown: float = 1.5
@export var melee_windup_time: float = 0.25
@export var melee_recover_time: float = 0.4
@export var melee_damage_mult: float = 1.0

@export_group("Boss Fase 2 (Despertar)")
## Misma lógica que el boss 1: al bajar de este porcentaje de vida despierta,
## se cura, se pone más rápido y cambia la música. Todo en la misma sala.
@export var phase_two_threshold: float = 0.5
## Cuánto se cura al despertar (boss 1: +20%).
@export var phase_two_heal_ratio: float = 0.2
## Multiplicador de ritmo de la fase 2 (boss 1: x1.5).
@export var phase_two_speed_mult: float = 1.5
## Música de cada fase. La de la fase 2 arranca con 4 compases de "despertar"
## pensados para durar lo mismo que la cinemática (~6 s).
@export var phase_two_music: AudioStream = preload("res://Audio/Music/Boss2_Fase2.ogg")
@export var phase_two_title: String = "◆ FASE 2: DESPERTAR ◆"

enum State {
	IDLE,
	JUMP_TELEGRAPH,
	JUMP_AIRBORNE,
	JUMP_LANDED,
	SPIT,
	SUMMON,
	MELEE
}

var current_state: State = State.IDLE

## Prioriza el sprite final del slime si ya está en la escena; si no,
## cae de vuelta al blob placeholder dibujado por código.
@onready var visual: Node2D = get_node_or_null("Slime2Sprite") if has_node("Slime2Sprite") else get_node_or_null("BossVisual")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var roar_sound: AudioStreamPlayer2D = get_node_or_null("Roar_sound")
@onready var slam_sound: AudioStreamPlayer2D = get_node_or_null("Slam_sound")
@onready var spit_sound: AudioStreamPlayer2D = get_node_or_null("Spit_sound")

var pattern_timer: Timer
var chase_timer: Timer
var melee_timer: Timer
var pattern_execute_count: int = 0
var jump_combo_remaining: int = 0
var spawned_minions: Array[Node2D] = []
var landing_shadow: LandingShadowMarker = null
var idle_bob_time: float = 0.0
var home_position: Vector2 = Vector2.ZERO

var healthbar_instance: Node = null
var boss_health_bar_node: Range = null
var is_phase_two: bool = false
var is_transitioning_phase: bool = false

func _ready() -> void:
	super._ready()
	has_footstep_fx = false
	damage = boss_damage
	max_health = boss_max_health
	current_health = max_health
	move_speed = 0.0 # Boss estacionario, se reposiciona saltando
	home_position = global_position
	_setup_pattern_timer()
	_setup_chase_timer()
	_setup_melee_timer()
	_connect_to_hud.call_deferred()
	_assign_sfx_bus()

func _assign_sfx_bus() -> void:
	if roar_sound: roar_sound.bus = "SFX"
	if slam_sound: slam_sound.bus = "SFX"
	if spit_sound: spit_sound.bus = "SFX"

func _setup_pattern_timer() -> void:
	pattern_timer = Timer.new()
	pattern_timer.wait_time = time_between_patterns
	pattern_timer.one_shot = false
	pattern_timer.autostart = true
	pattern_timer.timeout.connect(_on_pattern_timeout)
	add_child(pattern_timer)

func _setup_chase_timer() -> void:
	chase_timer = Timer.new()
	chase_timer.wait_time = chase_check_interval
	chase_timer.one_shot = false
	chase_timer.autostart = true
	chase_timer.timeout.connect(_on_chase_timer_timeout)
	add_child(chase_timer)

func _setup_melee_timer() -> void:
	melee_timer = Timer.new()
	melee_timer.wait_time = melee_attack_cooldown
	melee_timer.one_shot = false
	melee_timer.autostart = true
	melee_timer.timeout.connect(_on_melee_timer_timeout)
	add_child(melee_timer)

func _setup_health_bar() -> void:
	pass # Se usa la barra de boss grande en vez de la chica de EnemyBase

func apply_knockback(_force: float, _direction: Vector2) -> void:
	pass # Boss estacionario, no lo mueve el knockback

func process_movement(_delta: float) -> void:
	velocity = Vector2.ZERO

func _get_sprite() -> Node2D:
	return visual

func _hide_sprite() -> void:
	if visual:
		visual.hide()

func _physics_process(delta: float) -> void:
	if is_dying: return
	if current_state == State.IDLE:
		_process_idle_bob(delta)
	_update_visual_facing()

func _process_idle_bob(delta: float) -> void:
	idle_bob_time += delta
	if visual:
		visual.position.y = sin(idle_bob_time * 2.2) * 3.0

# Mantiene al sprite del slime mirando hacia el jugador (el placeholder
# dibujado por código no tiene este método, así que no hace nada con él).
func _update_visual_facing() -> void:
	if not visual or not target: return
	if not visual.has_method("face_towards"): return
	visual.face_towards(target.global_position - global_position)

# --- Persecución (el boss se mueve saltando hacia el jugador) ---

func _on_chase_timer_timeout() -> void:
	if is_dying: return
	if current_state != State.IDLE: return
	if not target: return
	var dist = global_position.distance_to(target.global_position)
	if dist <= chase_trigger_distance: return
	if dist > big_jump_distance:
		_start_chase_hop() # muy lejos: salto grande, telegrafiado, con daño
	else:
		_start_walk_hop() # acercamiento normal: saltitos chicos, sin daño

func _start_chase_hop() -> void:
	jump_combo_remaining = 0
	_begin_jump_to(_pick_chase_target())

func _pick_chase_target() -> Vector2:
	return _pick_step_target(chase_hop_distance)

func _pick_step_target(step_distance: float) -> Vector2:
	if not target: return global_position
	var to_player = target.global_position - global_position
	var dist = to_player.length()
	if dist < 0.001: return global_position
	var step = minf(step_distance, maxf(dist - melee_attack_range * 0.7, 0.0))
	var candidate = global_position + to_player.normalized() * step
	candidate.x = clampf(candidate.x, home_position.x - arena_half_extents.x, home_position.x + arena_half_extents.x)
	candidate.y = clampf(candidate.y, home_position.y - arena_half_extents.y, home_position.y + arena_half_extents.y)
	return candidate

# --- Saltito de caminata (acercamiento normal, sin telegrafiar ni dañar) ---

func _start_walk_hop() -> void:
	jump_combo_remaining = 0
	current_state = State.JUMP_TELEGRAPH
	var target_pos = _pick_step_target(walk_hop_distance)
	if visual:
		if visual.has_method("face_towards"):
			visual.face_towards(target_pos - global_position)
		visual.play_squash_down()
	get_tree().create_timer(walk_hop_telegraph_time).timeout.connect(_begin_walk_airborne.bind(target_pos))

func _begin_walk_airborne(target_pos: Vector2) -> void:
	if is_dying: return
	current_state = State.JUMP_AIRBORNE
	if visual:
		visual.play_stretch_up()
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	get_tree().create_timer(walk_hop_airborne_time).timeout.connect(_land_walk_hop.bind(target_pos))

func _land_walk_hop(target_pos: Vector2) -> void:
	if is_dying: return
	global_position = target_pos
	current_state = State.JUMP_LANDED
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if visual:
		visual.play_landing_impact() # solo el rebote visual, sin sombra ni daño
	get_tree().create_timer(walk_hop_recover_time).timeout.connect(_finish_pattern)

# --- Mordida cuerpo a cuerpo (cuando está pegado al jugador) ---

func _on_melee_timer_timeout() -> void:
	if is_dying: return
	if current_state != State.IDLE: return
	if not target: return
	if global_position.distance_to(target.global_position) <= melee_attack_range:
		_start_melee_attack()

func _start_melee_attack() -> void:
	current_state = State.MELEE
	if visual:
		if target and visual.has_method("face_towards"):
			visual.face_towards(target.global_position - global_position)
		if visual.has_method("play_attack"):
			visual.play_attack()
		else:
			visual.play_squash_down() # placeholder sin animación de ataque propia
	get_tree().create_timer(melee_windup_time).timeout.connect(_apply_melee_damage)

func _apply_melee_damage() -> void:
	if is_dying: return
	if visual:
		# Pulso de impacto (no pisa la animación de ataque, solo la escala).
		visual.play_squash_down()
	if slam_sound:
		slam_sound.play()
	if not is_transitioning_phase and target and global_position.distance_to(target.global_position) <= melee_attack_range * 1.15:
		if target.has_method("take_damage"):
			target.take_damage(int(float(damage) * melee_damage_mult), boss_display_name, global_position)
	get_tree().create_timer(melee_recover_time).timeout.connect(_finish_pattern)

# --- Selección de patrón ---

func _on_pattern_timeout() -> void:
	if is_dying: return
	if current_state != State.IDLE: return
	_pick_next_pattern()

func _pick_next_pattern() -> void:
	pattern_execute_count += 1
	if pattern_execute_count >= patterns_between_summon_check and not _has_living_minions():
		pattern_execute_count = 0
		_start_summon()
		return

	if not target:
		return

	if randf() < jump_pattern_chance:
		_start_jump_attack()
	else:
		_start_spit_attack()

func _finish_pattern() -> void:
	current_state = State.IDLE
	if visual:
		visual.reset_squash()
		if visual.has_method("play_idle"):
			visual.play_idle()

# --- Ataque de salto (telegrafiado -> aire -> aplastón), con combo opcional ---

func _start_jump_attack() -> void:
	jump_combo_remaining = 2 if randf() < triple_jump_chance else 0
	_do_single_jump()

func _do_single_jump() -> void:
	_begin_jump_to(_pick_jump_target())

func _begin_jump_to(target_pos: Vector2) -> void:
	current_state = State.JUMP_TELEGRAPH
	_show_landing_shadow(target_pos)
	if visual:
		if visual.has_method("face_towards"):
			visual.face_towards(target_pos - global_position)
		visual.play_squash_down()
	get_tree().create_timer(jump_telegraph_time).timeout.connect(_begin_airborne.bind(target_pos))

func _pick_jump_target() -> Vector2:
	var base = target.global_position if target else global_position
	var candidate = base + Vector2(randf_range(-70.0, 70.0), randf_range(-70.0, 70.0))
	if candidate.distance_to(base) < min_jump_distance_from_player:
		candidate = base + Vector2(min_jump_distance_from_player, 0).rotated(randf() * TAU)
	candidate.x = clampf(candidate.x, home_position.x - arena_half_extents.x, home_position.x + arena_half_extents.x)
	candidate.y = clampf(candidate.y, home_position.y - arena_half_extents.y, home_position.y + arena_half_extents.y)
	return candidate

func _begin_airborne(target_pos: Vector2) -> void:
	if is_dying: return
	current_state = State.JUMP_AIRBORNE
	if visual:
		visual.play_stretch_up()
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	get_tree().create_timer(jump_airborne_time).timeout.connect(_land_at.bind(target_pos))

func _land_at(target_pos: Vector2) -> void:
	if is_dying: return
	global_position = target_pos
	current_state = State.JUMP_LANDED
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	_hide_landing_shadow()
	if visual:
		visual.play_landing_impact()
	if slam_sound:
		slam_sound.play()
	_deal_slam_damage(target_pos)
	_shake_camera(18.0, 0.3)
	get_tree().create_timer(jump_recover_time).timeout.connect(_finish_jump_step)

func _finish_jump_step() -> void:
	if is_dying: return
	if jump_combo_remaining > 0:
		jump_combo_remaining -= 1
		_do_single_jump()
		return
	_finish_pattern()

func _deal_slam_damage(pos: Vector2) -> void:
	_spawn_shockwave(pos)
	if is_transitioning_phase: return # el jugador está congelado en la cinemática
	for body in get_tree().get_nodes_in_group("player"):
		if body.global_position.distance_to(pos) <= jump_slam_radius and body.has_method("take_damage"):
			body.take_damage(int(float(damage) * jump_slam_damage_mult), boss_display_name, pos)

func _spawn_shockwave(pos: Vector2) -> void:
	var wave = FuriaShockwave.new()
	wave.max_radius = jump_slam_radius
	get_tree().current_scene.add_child(wave)
	wave.global_position = pos

func _show_landing_shadow(pos: Vector2) -> void:
	if landing_shadow and is_instance_valid(landing_shadow):
		landing_shadow.queue_free()
	landing_shadow = LandingShadowMarker.new()
	landing_shadow.target_radius = jump_slam_radius * 0.55
	get_tree().current_scene.add_child(landing_shadow)
	landing_shadow.global_position = pos

func _hide_landing_shadow() -> void:
	if landing_shadow and is_instance_valid(landing_shadow):
		landing_shadow.fade_and_free()
	landing_shadow = null

# --- Ataque de vómito (proyectiles en abanico) ---

func _start_spit_attack() -> void:
	current_state = State.SPIT
	_do_spit_volley(spit_volleys)

func _do_spit_volley(volleys_left: int) -> void:
	if is_dying: return
	if volleys_left <= 0 or is_transitioning_phase:
		get_tree().create_timer(spit_recover_time).timeout.connect(_finish_pattern)
		return
	_fire_spit_volley()
	if spit_sound:
		spit_sound.play()
	get_tree().create_timer(spit_delay_between_volleys).timeout.connect(_do_spit_volley.bind(volleys_left - 1))

func _fire_spit_volley() -> void:
	if not spit_projectile_scene or not target: return
	if visual:
		visual.play_squash_down()
	var base_angle = (target.global_position - global_position).angle()
	var half_spread = deg_to_rad(spit_spread_degrees) * 0.5
	var count = spit_shots_per_volley
	for i in range(count):
		var t_ratio = 0.5 if count == 1 else float(i) / float(count - 1)
		var angle = lerp(base_angle - half_spread, base_angle + half_spread, t_ratio)
		_spawn_spit_projectile(angle)

func _spawn_spit_projectile(angle: float) -> void:
	var proj = spit_projectile_scene.instantiate()
	proj.source_name = boss_display_name
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	proj.setup(Vector2.from_angle(angle), damage, "player")

# --- Invocación de refuerzos ---

func _start_summon() -> void:
	current_state = State.SUMMON
	if roar_sound:
		roar_sound.play()
	_spawn_minions()
	get_tree().create_timer(summon_recover_time).timeout.connect(_finish_pattern)

func _spawn_minions() -> void:
	if not minion_scene: return
	for i in range(minion_spawn_count):
		var angle = (TAU / float(minion_spawn_count)) * i + randf_range(-0.3, 0.3)
		var offset = Vector2(120, 0).rotated(angle)
		_spawn_minion_at(global_position + offset)

func _spawn_minion_at(pos: Vector2) -> void:
	var inst = minion_scene.instantiate()
	get_parent().add_child(inst)
	inst.global_position = pos
	spawned_minions.append(inst)

func _has_living_minions() -> bool:
	_cleanup_dead_minions()
	return spawned_minions.size() > 0

func _cleanup_dead_minions() -> void:
	var alive: Array[Node2D] = []
	for m in spawned_minions:
		if is_instance_valid(m) and not _is_minion_dead(m):
			alive.append(m)
	spawned_minions = alive

func _is_minion_dead(m: Node2D) -> bool:
	if "is_dying" in m and m.is_dying:
		return true
	if "current_health" in m and m.current_health <= 0:
		return true
	return false

# --- Cámara, vida y muerte ---

func _shake_camera(force: float, duration: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_custom_camera_shake"):
		player.apply_custom_camera_shake(force, duration)

func take_damage(amount: int, is_crit: bool = false) -> void:
	if is_transitioning_phase: return # invulnerable mientras despierta (igual que el boss 1)
	super.take_damage(amount, is_crit)
	_update_hud_health()
	_check_phase_transition()

# --- Fase 2: "Despertar" (misma lógica que el boss 1, sin cambiar de sala) ---

func _check_phase_transition() -> void:
	if is_phase_two: return
	if is_dying: return
	if is_transitioning_phase: return
	if float(current_health) <= float(max_health) * phase_two_threshold:
		_trigger_phase_two()

func _trigger_phase_two() -> void:
	is_phase_two = true
	is_transitioning_phase = true
	jump_combo_remaining = 0 # si estaba en un combo de saltos, termina el salto actual y se queda
	_stop_boss_timers()
	_hide_landing_shadow()
	_set_minions_frozen(true)
	_play_rage_effects()
	_show_phase_two_message()
	_fade_out_boss_music(1.4)
	var t = create_tween()
	t.tween_interval(1.4)
	t.tween_callback(_start_phase_two_cinematic)

func _stop_boss_timers() -> void:
	for timer in [pattern_timer, chase_timer, melee_timer]:
		if timer:
			timer.stop()

func _play_rage_effects() -> void:
	if roar_sound:
		roar_sound.play()
	_shake_camera(20.0, 1.4)
	if visual:
		var t = create_tween()
		t.tween_property(visual, "modulate", Color(2.0, 0.4, 0.4), 0.2)
		t.tween_property(visual, "modulate", Color.WHITE, 1.0)

func _show_phase_two_message() -> void:
	var label = Label.new()
	label.text = "FASE 2: DESPERTAR"
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 12)
	var font_res = load("res://Art/Fonts/Dekatron-SemiBold.otf")
	if font_res:
		label.add_theme_font_override("font", font_res)

	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().current_scene.add_child(canvas_layer)
	canvas_layer.add_child(label)
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	label.position = Vector2(960 - 250, 540 - 40)

	var t = create_tween().set_parallel(true)
	t.tween_property(label, "scale", Vector2(1.2, 1.2), 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "modulate:a", 0.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(canvas_layer.queue_free)

# La cinemática es la del boss 1: título, zoom al boss, rugido + curación, zoom de vuelta.
func _start_phase_two_cinematic() -> void:
	if is_dying: return
	var player = get_tree().get_first_node_in_group("player")
	_freeze_player(player)
	_play_phase_two_music()

	var cinema_layer = CanvasLayer.new()
	cinema_layer.layer = 10
	get_tree().current_scene.add_child(cinema_layer)
	var title = _create_cinematic_title(cinema_layer)
	var camera = get_viewport().get_camera_2d()
	create_tween().tween_property(title, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_run_cinematic_timeline(cinema_layer, title, player, camera)

func _create_cinematic_title(parent: CanvasLayer) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.position = Vector2(960 - 350, 540 - 65)
	container.custom_minimum_size = Vector2(700, 130)
	container.modulate.a = 0.0
	parent.add_child(container)
	var font_res = load("res://Art/Fonts/Dekatron-SemiBold.otf")
	container.add_child(_make_cinematic_label(boss_display_name.to_upper(), 42, Color(1.0, 0.25, 0.25), 12, font_res))
	var sub_text = "%s\n[ REGENERACIÓN BIOLÓGICA +%d%% ]" % [phase_two_title, int(phase_two_heal_ratio * 100.0)]
	container.add_child(_make_cinematic_label(sub_text, 20, Color(0.3, 0.9, 1.0), 8, font_res))
	return container

func _make_cinematic_label(text: String, size: int, color: Color, outline: int, font_res: Font) -> Label:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_res:
		label.add_theme_font_override("font", font_res)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", outline)
	return label

# Mismos tiempos que el boss 1 (6 s): coinciden con los 4 compases de "despertar" de la música.
func _run_cinematic_timeline(cinema_layer: CanvasLayer, title: Control, player: Node, camera: Camera2D) -> void:
	var t = create_tween()
	t.tween_interval(1.0)
	t.tween_callback(func(): _zoom_camera_to_boss(camera, 1.0))
	t.tween_interval(1.0)
	t.tween_callback(_trigger_healing_effects)
	t.tween_interval(2.0)
	t.tween_callback(func(): _zoom_camera_to_player(camera, 1.0))
	t.tween_interval(1.0)
	t.tween_callback(func(): create_tween().tween_property(title, "modulate:a", 0.0, 0.4))
	t.tween_interval(1.0)
	t.tween_callback(func(): _finish_phase_two_cinematic(cinema_layer, player))

func _zoom_camera_to_boss(camera: Camera2D, duration: float) -> void:
	if not camera or not camera.get_parent(): return
	var target_offset = global_position - camera.get_parent().global_position
	var t = create_tween().set_parallel(true)
	t.tween_property(camera, "zoom", Vector2(1.35, 1.35), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(camera, "position", target_offset, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _zoom_camera_to_player(camera: Camera2D, duration: float) -> void:
	if not camera: return
	var t = create_tween().set_parallel(true)
	t.tween_property(camera, "zoom", Vector2.ONE, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(camera, "position", Vector2.ZERO, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func _trigger_healing_effects() -> void:
	if roar_sound:
		roar_sound.play()
	_shake_camera(16.0, 2.0)
	if visual:
		var t = create_tween()
		t.tween_property(visual, "modulate", Color(2.0, 0.3, 0.3), 0.3)
		t.tween_property(visual, "modulate", Color(0.3, 1.8, 0.6), 0.9)
		t.tween_property(visual, "modulate", Color.WHITE, 0.8)
	var particles = _create_healing_particles()
	var target_hp = mini(max_health, current_health + int(float(max_health) * phase_two_heal_ratio))
	var t_heal = create_tween()
	t_heal.tween_method(_update_healing_step, float(current_health), float(target_hp), 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t_heal.tween_interval(0.2)
	t_heal.tween_callback(particles.queue_free)

func _create_healing_particles() -> CPUParticles2D:
	var particles = CPUParticles2D.new()
	particles.amount = 40
	particles.lifetime = 1.6
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 55.0
	particles.direction = Vector2(0, -1)
	particles.spread = 60.0
	particles.gravity = Vector2(0, -80)
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 80.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.2, 1.0, 0.5, 0.9))
	gradient.set_color(1, Color(0.1, 0.8, 1.0, 0.0))
	particles.color_ramp = gradient
	add_child(particles)
	return particles

func _update_healing_step(val: float) -> void:
	current_health = int(val)
	if boss_health_bar_node:
		boss_health_bar_node.value = current_health

func _finish_phase_two_cinematic(cinema_layer: CanvasLayer, player: Node) -> void:
	if cinema_layer and is_instance_valid(cinema_layer):
		cinema_layer.queue_free()
	_unfreeze_player(player)
	_set_minions_frozen(false)
	_apply_phase_two_buffs()
	is_transitioning_phase = false

# Más rápido en todo, pero los saltos siguen telegrafiados para que se puedan esquivar.
func _apply_phase_two_buffs() -> void:
	var mult = maxf(phase_two_speed_mult, 0.01)
	jump_telegraph_time /= 1.2
	spit_volleys += 1
	if pattern_timer:
		pattern_timer.wait_time = time_between_patterns / mult
		pattern_timer.start()
	if chase_timer:
		chase_timer.wait_time = chase_check_interval / mult
		chase_timer.start()
	if melee_timer:
		melee_timer.wait_time = melee_attack_cooldown / mult
		melee_timer.start()

func _freeze_player(player: Node) -> void:
	if not player or not is_instance_valid(player): return
	if player.has_method("freeze_player"):
		player.freeze_player()

func _unfreeze_player(player: Node) -> void:
	if not player or not is_instance_valid(player): return
	if player.has_method("unfreeze_player"):
		player.unfreeze_player()

# los mutantes invocados se quedan quietos durante la cinemática
func _set_minions_frozen(frozen: bool) -> void:
	_cleanup_dead_minions()
	for m in spawned_minions:
		m.process_mode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT

# --- Música del boss (nodo Boss_Fight_Music de la sala) ---

func _get_boss_music() -> AudioStreamPlayer:
	# primero en la sala donde está el boss, después en la escena actual
	var music = get_parent().get_node_or_null("Boss_Fight_Music") if get_parent() else null
	if not music:
		music = get_tree().current_scene.get_node_or_null("Boss_Fight_Music")
	return music as AudioStreamPlayer

func _fade_out_boss_music(duration: float) -> void:
	var music = _get_boss_music()
	if not music or not music.playing: return
	music.set_meta("volumen_base", music.volume_db)
	create_tween().tween_property(music, "volume_db", music.volume_db - 30.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _play_phase_two_music() -> void:
	var music = _get_boss_music()
	if not music or not phase_two_music: return
	music.volume_db = music.get_meta("volumen_base", music.volume_db)
	music.stream = phase_two_music
	music.play()

func _update_hud_health() -> void:
	if boss_health_bar_node:
		var t = create_tween()
		t.tween_property(boss_health_bar_node, "value", float(maxi(0, current_health)), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func die() -> void:
	super.die()
	if pattern_timer:
		pattern_timer.stop()
	if chase_timer:
		chase_timer.stop()
	if melee_timer:
		melee_timer.stop()
	if landing_shadow and is_instance_valid(landing_shadow):
		landing_shadow.queue_free()
	_hide_hud_health()

func _hide_hud_health() -> void:
	if healthbar_instance:
		healthbar_instance.queue_free()
		healthbar_instance = null
		boss_health_bar_node = null

# --- HUD de vida del boss (mismo patrón que boss1.gd) ---

func _connect_to_hud() -> void:
	var scene = _load_healthbar_scene()
	if not scene:
		printerr("Boss2: No se pudo encontrar la escena boss_health_bar.tscn.")
		return

	healthbar_instance = scene.instantiate()
	if healthbar_instance is CanvasLayer:
		healthbar_instance.layer = 100
	get_tree().current_scene.add_child(healthbar_instance)

	boss_health_bar_node = _find_progress_bar(healthbar_instance)
	if boss_health_bar_node:
		boss_health_bar_node.max_value = max_health
		boss_health_bar_node.value = current_health

	var name_label = _find_label(healthbar_instance)
	if name_label:
		name_label.text = boss_display_name

	var anim_player = _find_animation_player(healthbar_instance)
	if anim_player:
		if anim_player.has_animation("Start_Fight"):
			anim_player.play("Start_Fight")
		elif anim_player.has_animation("start_fight"):
			anim_player.play("start_fight")
		elif anim_player.get_animation_list().size() > 0:
			anim_player.play(anim_player.get_animation_list()[0])

func _load_healthbar_scene() -> PackedScene:
	var paths = [
		"res://Scenes/UI/boss_health_bar.tscn",
		"res://Scenes/UI/Boss_healtbar.tscn",
		"res://Scenes/UI/Boss_healthbar.tscn",
	]
	for path in paths:
		if ResourceLoader.exists(path):
			return load(path)
	return null

func _find_label(node: Node) -> Label:
	if node is Label:
		return node
	for i in range(node.get_child_count()):
		var found = _find_label(node.get_child(i))
		if found:
			return found
	return null

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for i in range(node.get_child_count()):
		var found = _find_animation_player(node.get_child(i))
		if found:
			return found
	return null

func _find_progress_bar(node: Node) -> Range:
	if node is Range:
		return node
	for i in range(node.get_child_count()):
		var found = _find_progress_bar(node.get_child(i))
		if found:
			return found
	return null
