extends EnemyBase
class_name Boss2

## El Primogénito, jefe de La Cripta (inspirado en Monstro, de TBoI): el primer
## Lázaro fallido, convertido en una masa de carne. Persigue a los saltos,
## muerde cuerpo a cuerpo, hace el "gran salto" (desaparece hacia arriba, su
## sombra te sigue y cae soltando un anillo de huesos), escupe bilis en abanico
## que deja charcos y, si lo acorralan, vomita ghouls y abejas carnívoras.
## Al 40% de vida despierta (fase 2). El slime es arte provisional.
## La lógica no depende de la sala: usa la posición inicial como "centro" y un
## rango configurable para saber hasta dónde puede saltar.

@export_group("Boss Base Stats")
@export var boss_max_health: int = 1400
@export var boss_damage: int = 22
@export var boss_display_name: String = "El Primogénito"

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

@export_group("Gran salto")
## Probabilidad de elegir el gran salto como patrón (fase 1).
@export var great_leap_chance: float = 0.3
@export var great_leap_rise_time: float = 0.35
## Cuánto tiempo la sombra persigue al jugador antes de quedarse quieta.
@export var great_leap_hunt_time: float = 1.3
@export var great_leap_lock_time: float = 0.45
@export var great_leap_fall_time: float = 0.18
@export var great_leap_height: float = 520.0
## Qué tan rápido la sombra alcanza al jugador.
@export var great_leap_follow_speed: float = 4.0
@export var great_leap_slam_radius: float = 115.0
@export var bone_scene: PackedScene = preload("res://Scenes/Projectiles/crypt_projectile.tscn")
@export var bone_ring_count: int = 12
@export var bone_speed: float = 210.0
@export var bone_damage_ratio: float = 0.6

@export_group("Boss Spit Attack")
## Escupe bilis en abanico: cada escupitajo cae en arco y deja un charco.
@export var spit_volleys: int = 2
@export var spit_shots_per_volley: int = 3
@export var spit_spread_degrees: float = 40.0
@export var bile_damage_ratio: float = 0.5
@export var bile_min_distance: float = 90.0
@export var bile_max_distance: float = 330.0
@export var bile_puddle_radius: float = 30.0
@export var bile_puddle_duration: float = 4.5
@export var spit_delay_between_volleys: float = 0.5
@export var spit_recover_time: float = 0.5

@export_group("Boss Summon")
## Vomita estos enemigos, alternando (ghoul, abeja, ghoul...).
@export var minion_scenes: Array[PackedScene] = [preload("res://Scenes/Enemies/Crypt/CryptGhoul.tscn"), preload("res://Scenes/Enemies/Crypt/CryptFleshBee.tscn")]
@export var minion_spawn_count: int = 2
## Si el jugador se queda pegado a él este tiempo, vomita refuerzos.
@export var cornered_summon_time: float = 4.0
@export var summon_recover_time: float = 0.6

@export_group("Boss Chase")
## Debajo de esta distancia no hace falta perseguir (ya está en rango de
## mordida, o casi).
@export var chase_trigger_distance: float = 110.0
## Más allá de esta distancia usa el gran salto para cerrar la brecha de golpe.
## Por debajo, se acerca con saltitos chicos (ver Boss Walk Hop), sin
## telegrafiar ni hacer daño.
@export var big_jump_distance: float = 480.0
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
@export var phase_two_threshold: float = 0.4
## Cuánto se cura al despertar (boss 1: +20%).
@export var phase_two_heal_ratio: float = 0.2
## Multiplicador de ritmo de la fase 2 (boss 1: x1.5).
@export var phase_two_speed_mult: float = 1.5
## Música de cada fase. La de la fase 2 arranca con 4 compases de "despertar"
## pensados para durar lo mismo que la cinemática (~6 s).
@export var phase_two_music: AudioStream = preload("res://Audio/Music/Boss2_Fase2.ogg")
@export var phase_two_title: String = "EL HAMBRE DESPIERTA"

enum State {
	IDLE,
	JUMP_TELEGRAPH,
	JUMP_AIRBORNE,
	JUMP_LANDED,
	SPIT,
	SUMMON,
	MELEE,
	GREAT_LEAP
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

var healthbar_instance: BossHealthBar = null
var boss_health_bar_node: Range = null
var is_phase_two: bool = false
var is_transitioning_phase: bool = false
var great_leap_combo: int = 0
var _leap_hunting: bool = false
var _cornered_time: float = 0.0
var _camera_rest_zoom: Vector2 = Vector2.ONE
var _intro_falling := false
var _intro_shadow_scale := Vector2.ONE
var _camera_rest_offset: Vector2 = Vector2.ZERO

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
	add_to_group("boss_entrance") # el HUD no muestra el cartel de sala: lo hace el jefe
	_start_entrance.call_deferred()
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
	if current_state == State.IDLE and not _intro_falling:
		_process_idle_bob(delta)
	if _leap_hunting:
		_hunt_with_shadow(delta)
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
	if dist <= chase_trigger_distance:
		_check_cornered()
		return
	_cornered_time = 0.0
	if dist > big_jump_distance:
		_start_great_leap() # muy lejos: desaparece y cae encima
	else:
		_start_walk_hop() # acercamiento normal: saltitos chicos, sin daño

# Si el jugador se le queda pegado, vomita refuerzos para sacárselo de encima.
func _check_cornered() -> void:
	_cornered_time += chase_timer.wait_time
	if _cornered_time < cornered_summon_time or _has_living_minions(): return
	_cornered_time = 0.0
	_start_summon()

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

	var roll = randf()
	if roll < great_leap_chance:
		_start_great_leap()
	elif randf() < jump_pattern_chance:
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

func _deal_slam_damage(pos: Vector2, radius: float = -1.0) -> void:
	if radius <= 0.0: radius = jump_slam_radius
	_spawn_shockwave(pos, radius)
	if is_transitioning_phase: return # el jugador está congelado en la cinemática
	for body in get_tree().get_nodes_in_group("player"):
		if body.global_position.distance_to(pos) <= radius and body.has_method("take_damage"):
			body.take_damage(int(float(damage) * jump_slam_damage_mult), boss_display_name, pos)

func _spawn_shockwave(pos: Vector2, radius: float) -> void:
	var wave = FuriaShockwave.new()
	wave.max_radius = radius
	get_tree().current_scene.add_child(wave)
	wave.global_position = pos

func _show_landing_shadow(pos: Vector2, radius: float = -1.0) -> void:
	if landing_shadow and is_instance_valid(landing_shadow):
		landing_shadow.queue_free()
	landing_shadow = LandingShadowMarker.new()
	landing_shadow.target_radius = jump_slam_radius * 0.55 if radius <= 0.0 else radius
	get_tree().current_scene.add_child(landing_shadow)
	landing_shadow.global_position = pos

func _hide_landing_shadow() -> void:
	if landing_shadow and is_instance_valid(landing_shadow):
		landing_shadow.fade_and_free()
	landing_shadow = null

# --- Gran salto: desaparece hacia arriba, la sombra te sigue y cae encima ---

func _start_great_leap() -> void:
	if not target: return
	current_state = State.GREAT_LEAP
	jump_combo_remaining = great_leap_combo
	_leap_windup()

func _leap_windup() -> void:
	if visual:
		visual.play_squash_down()
	get_tree().create_timer(0.25).timeout.connect(_leap_rise)

func _leap_rise() -> void:
	if is_dying: return
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	_set_ground_shadow_visible(false)
	if not visual:
		_leap_hunt()
		return
	visual.play_stretch_up()
	var t = create_tween()
	t.tween_property(visual, "position:y", -great_leap_height, great_leap_rise_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(visual, "modulate:a", 0.0, great_leap_rise_time).set_delay(great_leap_rise_time * 0.6)
	t.tween_callback(_leap_hunt)

func _leap_hunt() -> void:
	if is_dying: return
	_show_landing_shadow(_clamp_to_arena(target.global_position) if target else global_position, great_leap_slam_radius * 0.6)
	_leap_hunting = true
	get_tree().create_timer(great_leap_hunt_time).timeout.connect(_leap_lock)

# La sombra persigue al jugador mientras el boss está "en el techo".
func _hunt_with_shadow(delta: float) -> void:
	if not target or not landing_shadow or not is_instance_valid(landing_shadow): return
	var goal = _clamp_to_arena(target.global_position)
	landing_shadow.global_position = landing_shadow.global_position.lerp(goal, minf(1.0, great_leap_follow_speed * delta))

func _leap_lock() -> void:
	_leap_hunting = false
	if is_dying: return
	if landing_shadow and is_instance_valid(landing_shadow):
		var pulse = landing_shadow.create_tween()
		pulse.tween_property(landing_shadow, "scale", landing_shadow.scale * 1.18, great_leap_lock_time).set_trans(Tween.TRANS_SINE)
	get_tree().create_timer(great_leap_lock_time).timeout.connect(_leap_fall)

func _leap_fall() -> void:
	if is_dying: return
	var pos = landing_shadow.global_position if landing_shadow and is_instance_valid(landing_shadow) else global_position
	global_position = pos
	if not visual:
		_leap_land(pos)
		return
	visual.modulate.a = 1.0
	var t = create_tween()
	t.tween_property(visual, "position:y", 0.0, great_leap_fall_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(_leap_land.bind(pos))

func _leap_land(pos: Vector2) -> void:
	if is_dying: return
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	_set_ground_shadow_visible(true)
	_hide_landing_shadow()
	if visual:
		visual.play_landing_impact()
	if slam_sound:
		slam_sound.play()
	_deal_slam_damage(pos, great_leap_slam_radius)
	_spawn_bone_ring(pos)
	_shake_camera(24.0, 0.4)
	get_tree().create_timer(jump_recover_time + 0.2).timeout.connect(_finish_great_leap)

func _finish_great_leap() -> void:
	if is_dying: return
	if jump_combo_remaining > 0 and not is_transitioning_phase:
		jump_combo_remaining -= 1
		_leap_windup()
		return
	_finish_pattern()

# Al caer suelta un anillo de huesos que sale en todas direcciones.
func _spawn_bone_ring(pos: Vector2) -> void:
	if is_transitioning_phase or not bone_scene: return
	var offset_angle = randf() * TAU
	for i in bone_ring_count:
		var dir = Vector2.from_angle(offset_angle + TAU * float(i) / float(bone_ring_count))
		var bone = bone_scene.instantiate()
		bone.direction = dir
		bone.damage = int(float(damage) * bone_damage_ratio)
		bone.speed = bone_speed
		bone.source_name = boss_display_name
		_paint_bone(bone)
		get_parent().add_child(bone)
		bone.global_position = pos + dir * 40.0

func _paint_bone(bone: Node) -> void:
	var body = bone.get_node_or_null("Body")
	if body: body.color = Color(0.93, 0.9, 0.8)
	var trail = bone.get_node_or_null("Trail")
	if trail: trail.default_color = Color(0.9, 0.86, 0.75, 0.45)

func _set_ground_shadow_visible(show_shadow: bool) -> void:
	var shadow = get_node_or_null("DropShadow")
	if shadow: shadow.visible = show_shadow

func _clamp_to_arena(pos: Vector2) -> Vector2:
	pos.x = clampf(pos.x, home_position.x - arena_half_extents.x, home_position.x + arena_half_extents.x)
	pos.y = clampf(pos.y, home_position.y - arena_half_extents.y, home_position.y + arena_half_extents.y)
	return pos

# --- Ataque de vómito (bilis en abanico que deja charcos) ---

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
	if not target: return
	if visual:
		visual.play_squash_down()
	var base_angle = (target.global_position - global_position).angle()
	var distance = clampf(global_position.distance_to(target.global_position), bile_min_distance, bile_max_distance)
	var half_spread = deg_to_rad(spit_spread_degrees) * 0.5
	var count = spit_shots_per_volley
	for i in range(count):
		var t_ratio = 0.5 if count == 1 else float(i) / float(count - 1)
		var angle = lerp(base_angle - half_spread, base_angle + half_spread, t_ratio)
		_spawn_bile(global_position + Vector2.from_angle(angle) * distance * randf_range(0.85, 1.1))

func _spawn_bile(landing: Vector2, glob_damage: int = -1, puddle_radius: float = -1.0) -> BileGlob:
	var glob = BileGlob.new()
	glob.damage = int(float(damage) * bile_damage_ratio) if glob_damage < 0 else glob_damage
	glob.puddle_radius = bile_puddle_radius if puddle_radius < 0.0 else puddle_radius
	glob.puddle_duration = bile_puddle_duration
	glob.source_name = boss_display_name
	get_parent().add_child(glob)
	glob.launch(global_position, _clamp_to_arena(landing))
	return glob

# --- Invocación de refuerzos ---

func _start_summon() -> void:
	current_state = State.SUMMON
	if roar_sound:
		roar_sound.play()
	_spawn_minions()
	get_tree().create_timer(summon_recover_time).timeout.connect(_finish_pattern)

# Los vomita: cada uno sale volando en un escupitajo y aparece donde cae.
func _spawn_minions() -> void:
	if minion_scenes.is_empty(): return
	if visual:
		visual.play_squash_down()
	for i in range(minion_spawn_count):
		var angle = (TAU / float(minion_spawn_count)) * i + randf_range(-0.3, 0.3)
		var pos = _clamp_to_arena(global_position + Vector2(120, 0).rotated(angle))
		var glob = _spawn_bile(pos, 0, 18.0)
		get_tree().create_timer(glob.flight_time).timeout.connect(_spawn_minion_at.bind(minion_scenes[i % minion_scenes.size()], pos))

func _spawn_minion_at(scene: PackedScene, pos: Vector2) -> void:
	if is_dying or not scene: return
	var inst = scene.instantiate()
	if "is_summoned" in inst: inst.is_summoned = true
	if "flesh_drop_chance" in inst: inst.flesh_drop_chance = 0.0
	if "item_drop_chance" in inst: inst.item_drop_chance = 0.0
	get_parent().add_child(inst)
	inst.global_position = pos
	if inst.has_method("alert_to_player"): inst.alert_to_player()
	if inst.has_method("spawn_appear"): inst.spawn_appear()
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

# La cinemática es la del boss 1: título, zoom al boss, rugido + curación, zoom de vuelta.
func _start_phase_two_cinematic() -> void:
	if is_dying: return
	var player = get_tree().get_first_node_in_group("player")
	_freeze_player(player)
	_play_phase_two_music()

	var cinema_layer = CanvasLayer.new()
	cinema_layer.layer = 10
	get_tree().current_scene.add_child(cinema_layer)
	# cartel de fase animado (BossPhaseBanner), igual en los tres jefes
	var heal_text = "REGENERACIÓN BIOLÓGICA +%d%%" % int(phase_two_heal_ratio * 100.0)
	BossPhaseBanner.show_phase(get_tree(), 2, phase_two_title, heal_text, Color("#9BD14B"))
	var camera = get_viewport().get_camera_2d()
	_run_cinematic_timeline(cinema_layer, player, camera)

# Mismos tiempos que el boss 1 (6 s): coinciden con los 4 compases de "despertar" de la música.
func _run_cinematic_timeline(cinema_layer: CanvasLayer, player: Node, camera: Camera2D) -> void:
	var t = create_tween()
	t.tween_interval(1.0)
	t.tween_callback(_zoom_camera_to_boss.bind(camera, 1.0))
	t.tween_interval(1.0)
	t.tween_callback(_trigger_healing_effects)
	t.tween_interval(2.0)
	t.tween_callback(_zoom_camera_to_player.bind(camera, 1.0))
	t.tween_interval(1.0)
	t.tween_interval(1.0)
	t.tween_callback(_finish_phase_two_cinematic.bind(cinema_layer, player))

# El zoom es relativo al de la pelea (la cámara del jugador no está en 1x):
# antes se iba a 1.35 y volvía a 1.0, o sea que se alejaba de más y se veía
# el vacío negro y la niebla fuera de la sala.
func _zoom_camera_to_boss(camera: Camera2D, duration: float) -> void:
	if not camera or not camera.get_parent(): return
	_camera_rest_zoom = camera.zoom
	_camera_rest_offset = camera.position
	var target_offset = global_position - camera.get_parent().global_position
	var t = create_tween().set_parallel(true)
	t.tween_property(camera, "zoom", _camera_rest_zoom * 1.25, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(camera, "position", target_offset, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _zoom_camera_to_player(camera: Camera2D, duration: float) -> void:
	if not camera: return
	var t = create_tween().set_parallel(true)
	t.tween_property(camera, "zoom", _camera_rest_zoom, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(camera, "position", _camera_rest_offset, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

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
	# despierto: la sombra te alcanza antes, encadena dos grandes saltos y suelta más huesos
	great_leap_chance = maxf(great_leap_chance, 0.4)
	great_leap_hunt_time *= 0.75
	great_leap_follow_speed *= 1.3
	great_leap_combo = 1
	bone_ring_count += 4
	bile_puddle_duration += 1.5
	if visual:
		visual.self_modulate = Color(1.15, 0.82, 0.82)
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
	_leap_hunting = false
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
	if healthbar_instance and is_instance_valid(healthbar_instance):
		healthbar_instance.close()
		healthbar_instance = null
		boss_health_bar_node = null

# --- Entrada y barra de vida (ver BossIntro y BossHealthBar) ---

# La cámara va hasta el jefe, ruge, y el título entra y se convierte en la barra.
func _start_entrance() -> void:
	var intro = BossIntro.new()
	add_child(intro)
	intro.roared.connect(_connect_to_hud)
	await intro.play(self, 0.6)
	if not is_dying:
		_connect_to_hud()

# --- Aparición: cae desde arriba y rebota ---
# Primero crece su sombra en el piso, después cae en picada, aplasta el suelo
# (onda, polvo, temblor) y da dos rebotes cada vez más chicos antes de rugir.

const INTRO_DROP_HEIGHT := 420.0

func _intro_prepare() -> void:
	if not visual: return
	_intro_falling = true
	visual.position.y = -INTRO_DROP_HEIGHT
	visual.modulate.a = 0.0
	var shadow = get_node_or_null("DropShadow") as Node2D
	if shadow:
		_intro_shadow_scale = shadow.scale
		shadow.scale = _intro_shadow_scale * 0.15
		shadow.self_modulate.a = 0.0

func _intro_appear() -> void:
	if not visual: return
	var shadow = get_node_or_null("DropShadow") as Node2D
	if shadow:
		var ts = create_tween().set_parallel(true)
		ts.tween_property(shadow, "scale", _intro_shadow_scale, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		ts.tween_property(shadow, "self_modulate:a", 1.0, 0.9)
	var t = create_tween()
	t.tween_interval(0.35)
	t.tween_callback(_start_intro_visual)
	t.tween_property(visual, "position:y", 0.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(_intro_land.bind(1.0))
	t.tween_property(visual, "position:y", -70.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(visual, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(_intro_land.bind(0.5))
	t.tween_property(visual, "position:y", -22.0, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(visual, "position:y", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(_intro_land.bind(0.2))
	t.tween_interval(0.25)
	await t.finished
	_intro_falling = false
	if slam_sound: slam_sound.pitch_scale = 1.0

func _start_intro_visual() -> void:
	if not is_instance_valid(visual):
		return
	visual.modulate.a = 1.0
	if visual.has_method("play_stretch_up"):
		visual.play_stretch_up()

# strength 1 = la caída fuerte; los rebotes golpean menos.
func _intro_land(strength: float) -> void:
	if visual and visual.has_method("play_landing_impact"):
		visual.play_landing_impact()
	if slam_sound:
		slam_sound.pitch_scale = 1.0 + (1.0 - strength) * 0.25
		slam_sound.play()
	_shake_camera(24.0 * strength, 0.25 + 0.2 * strength)
	if strength >= 0.5:
		_spawn_shockwave(global_position, 150.0 * strength)
	_spawn_landing_dust(strength)

func _spawn_landing_dust(strength: float) -> void:
	var p = CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = int(30 * strength) + 6
	p.lifetime = 0.8
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(40, 4)
	p.direction = Vector2(0, -1)
	p.spread = 80.0
	p.gravity = Vector2(0, 220)
	p.initial_velocity_min = 60.0 * strength
	p.initial_velocity_max = 160.0 * strength
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	var g = Gradient.new()
	g.set_color(0, Color(0.55, 0.45, 0.65, 0.9))
	g.set_color(1, Color(0.3, 0.25, 0.35, 0.0))
	p.color_ramp = g
	p.position = Vector2(0, 24)
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

# Lo llama BossIntro cuando la cámara llega al jefe.
func _intro_roar() -> void:
	if roar_sound:
		roar_sound.play()
	if visual:
		var base_scale = visual.scale
		var t = create_tween()
		t.tween_property(visual, "scale", base_scale * Vector2(1.15, 0.85), 0.12)
		t.parallel().tween_property(visual, "modulate", Color(1.8, 0.6, 0.6), 0.12)
		t.tween_property(visual, "scale", base_scale, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(visual, "modulate", Color.WHITE, 0.8)

func _connect_to_hud() -> void:
	if healthbar_instance and is_instance_valid(healthbar_instance): return
	var created = BossBarHelper.create(get_tree(), boss_display_name, max_health, current_health, {"phase_marks": [phase_two_threshold]})
	healthbar_instance = created.get("instance")
	boss_health_bar_node = created.get("bar")
