extends EnemyBase
class_name Boss3Prometeo

## PROMETEO, boss final (zona 3). Un reflejo oscuro de Lázaro: usa en contra
## del jugador todo lo que el jugador fue aprendiendo.
## - Cambia de arma cada pocos ataques (pistola, escopeta, uzi, hacha, daga y,
##   desde la fase 2, minigun, lanzallamas, colmena y maza). Ver PrometeoArsenal.
## - Se mueve en círculos alrededor del jugador a la distancia que le conviene
##   al arma que tiene, y se mete con dash cuando el arma es de cuerpo a cuerpo.
## - Esquiva balas con un dash lateral (no siempre: depende de la fase).
## - Lee al jugador: apunta adelantándose a su movimiento y castiga cuando el
##   jugador acaba de gastar su dash.
## Fases:
##   1 (100% - 65%): "El reflejo". Armas básicas.
##   2 (65% - 30%): "Espejo". Se desdobla: un clon (solo armas a distancia)
##      pelea con él un rato mientras el original presiona cuerpo a cuerpo.
##   3 (30% - 0%): "El fuego robado". Más rápido, remata los golpes con un
##      escopetazo y cada tanto gira espirales de fuego desde el centro.

const SELF_SCENE_PATH := "res://Scenes/Enemies/Boss3_Prometeo.tscn"

@export_group("Prometeo Base")
@export var boss_max_health: int = 2600
@export var bullet_damage: int = 14
@export var melee_damage: int = 22
@export var boss_display_name: String = "PROMETEO"

@export_group("Prometeo Entrada")
## Segundos desde que carga la sala hasta que arranca la cinemática de entrada.
@export var intro_delay: float = 1.0
## Texto opcional debajo del nombre en la entrada (vacío = solo el nombre).
@export var intro_subtitle: String = ""

@export_group("Prometeo Arena")
## Hasta dónde se puede alejar de su posición inicial (centro de la arena).
## Ajustar cuando esté la sala real.
@export var arena_half_extents: Vector2 = Vector2(300, 200)

@export_group("Prometeo Movimiento")
@export var strafe_speed: float = 130.0
@export var dash_speed: float = 560.0
@export var max_dash_distance: float = 260.0
@export var dodge_chance: float = 0.35
@export var dodge_cooldown: float = 2.2
@export var dodge_distance: float = 95.0
@export var action_delay_min: float = 0.8
@export var action_delay_max: float = 1.3
## Cuántos ataques hace con cada arma antes de cambiarla (mín, máx).
@export var attacks_per_weapon: Vector2i = Vector2i(2, 3)

@export_group("Prometeo Fases")
@export var phase_two_threshold: float = 0.65
@export var phase_three_threshold: float = 0.30
@export var clone_health_ratio: float = 0.18
@export var clone_lifetime: float = 18.0
## Música de cada fase (opcional). Si están vacías sigue sonando la de la sala.
@export var phase_two_music: AudioStream
@export var phase_three_music: AudioStream

## Lo setea el original al desdoblarse. El clon solo usa armas a distancia,
## no tiene barra grande ni fases, no suelta loot y se disuelve solo.
@export var is_clone: bool = false
var clone_owner: Node2D = null

enum State { INTRO, NEUTRAL, ATTACKING, TRANSITION }

var state: State = State.INTRO
var phase: int = 1
var aim_lead: float = 0.6
var is_transitioning_phase: bool = false

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var arsenal: PrometeoArsenal = get_node_or_null("Arsenal")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

var home_position: Vector2 = Vector2.ZERO
var _pace: float = 1.0
var _action_timer: float = 1.0
var _action_serial: int = 0
var _attacks_left: int = 0
var _actions_since_spiral: int = 0
var _attack_mobility: float = 0.0
var _orbit_sign: float = 1.0
var _orbit_timer: float = 2.0
var _facing: Vector2 = Vector2.DOWN

var _dash_velocity: Vector2 = Vector2.ZERO
var _dash_time_left: float = 0.0
var _dash_invulnerable: bool = false
var _ghost_timer: float = 0.0
var _dodge_cd: float = 0.0
var _is_airborne: bool = false
var _player_was_dashing: bool = false
var _too_close_time: float = 0.0

var _clones: Array[Node2D] = []
var _bar_instance: Node = null
var _bar: Range = null
var _sounds: Dictionary = {}

func _ready() -> void:
	max_health = boss_max_health
	move_speed = strafe_speed
	damage = bullet_damage
	super._ready()
	has_footstep_fx = true
	home_position = global_position
	_collect_sounds()
	_build_threat_sensor()
	_build_shadow_aura()
	if arsenal:
		arsenal.setup(self)
		arsenal.equip(_choose_next_weapon(), false)
	_attacks_left = randi_range(attacks_per_weapon.x, attacks_per_weapon.y)
	_apply_phase_stats()
	if is_clone:
		return # el original lo arranca con begin_as_clone()
	_play_intro()

# --- Base de EnemyBase que el boss no usa igual ---

func _setup_health_bar() -> void:
	if not is_clone: return # el original usa la barra grande
	super._setup_health_bar()
	var bar = get_node_or_null("HealthBar")
	if bar:
		bar.position = Vector2(-20, -62)
		bar.custom_minimum_size = Vector2(40, 4)

func apply_knockback(_force: float, _direction: Vector2) -> void:
	pass # no lo empuja nada: se mueve solo por decisión propia

func freeze_enemy(duration: float = 5.0) -> void:
	super.freeze_enemy(minf(duration, 0.8)) # el hielo lo frena apenas

# Entrada propia del códice (la de EnemyBase desbloquearía la del boss 1).
func _unlock_bestiary_entry() -> void:
	if is_clone or not GameData.has_method("unlock_codex_entry"): return
	GameData.unlock_codex_entry("enemies", "boss3")

func _attempt_drops() -> void:
	if is_clone: return
	super._attempt_drops()

# --- Bucle principal ---

func _physics_process(delta: float) -> void:
	if is_dying: return
	super._physics_process(delta)
	_update_timers(delta)
	_read_player(delta)
	_update_dash_ghosts(delta)
	_update_visuals()

func process_movement(delta: float) -> void:
	if _dash_time_left > 0.0:
		_dash_time_left -= delta
		velocity = _dash_velocity
		return
	if _is_airborne or state == State.INTRO or state == State.TRANSITION:
		velocity = Vector2.ZERO
		return
	if state == State.ATTACKING:
		velocity = _neutral_velocity() * _attack_mobility
		return
	velocity = _neutral_velocity()
	_action_timer -= delta
	if _action_timer <= 0.0:
		_start_next_action()

func _update_timers(delta: float) -> void:
	_dodge_cd = maxf(0.0, _dodge_cd - delta)
	_orbit_timer -= delta
	if _orbit_timer <= 0.0:
		_orbit_sign = -_orbit_sign
		_orbit_timer = randf_range(1.4, 3.0)

# --- Lectura del jugador ---

func _read_player(delta: float) -> void:
	if not target or not is_instance_valid(target): return
	_punish_spent_dash()
	_track_too_close(delta)

# Cuando el jugador termina su dash y lo tiene en enfriamiento, Prometeo
# aprovecha y ataca ya (el jugador no tiene con qué esquivar).
func _punish_spent_dash() -> void:
	var dashing = target.get("is_dashing") == true
	if _player_was_dashing and not dashing and state == State.NEUTRAL and _player_dash_on_cooldown():
		_action_timer = minf(_action_timer, 0.15)
	_player_was_dashing = dashing

func _player_dash_on_cooldown() -> bool:
	var cd = target.get("dash_cd_timer") as Timer
	return cd != null and not cd.is_stopped()

# Si el jugador se le pega mientras tiene un arma de distancia, se aleja con un
# dash para recuperar el espacio (como haría un jugador).
func _track_too_close(delta: float) -> void:
	if state != State.NEUTRAL or not arsenal or arsenal.is_melee(arsenal.current_id):
		_too_close_time = 0.0
		return
	_too_close_time = _too_close_time + delta if distance_to_target() < 55.0 else 0.0
	if _too_close_time > 0.7 and _dash_time_left <= 0.0:
		_too_close_time = 0.0
		var away = (global_position - target.global_position).normalized().rotated(randf_range(-0.6, 0.6))
		dash(away, 150.0, true)

# --- Movimiento neutral: orbitar al jugador a la distancia del arma ---

func _neutral_velocity() -> Vector2:
	if not target or not is_instance_valid(target): return Vector2.ZERO
	if not has_line_of_sight_to_player():
		return get_nav_direction_to_target() * move_speed * _pace
	var to_target = target.global_position - global_position
	var dist = to_target.length()
	if dist < 1.0: return Vector2.ZERO
	var desired = arsenal.preferred_range(arsenal.current_id) if arsenal else 180.0
	if is_clone:
		desired = maxf(desired, 200.0)
	var radial = to_target / dist * clampf((dist - desired) / 60.0, -1.0, 1.0)
	var tangent = Vector2(-to_target.y, to_target.x) / dist * _orbit_sign * 0.8
	var dir = (radial + tangent).normalized()
	if _is_blocked(dir):
		_orbit_sign = -_orbit_sign
		dir = (radial - tangent).normalized()
	return dir * move_speed * _pace

func _is_blocked(dir: Vector2) -> bool:
	return _ray_hit(global_position, global_position + dir * 40.0) != Vector2.INF

func _ray_hit(from: Vector2, to: Vector2) -> Vector2:
	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [get_rid()]
	query.collision_mask = 1
	var result = get_world_2d().direct_space_state.intersect_ray(query)
	return result.position if not result.is_empty() else Vector2.INF

# --- Cerebro: elegir y ejecutar la próxima acción ---

func _start_next_action() -> void:
	var serial = _action_serial
	state = State.ATTACKING
	_attack_mobility = 0.0
	if _attacks_left <= 0:
		await _swap_weapon()
		if serial != _action_serial or is_dying: return
	if _should_cast_spiral():
		_actions_since_spiral = 0
		await arsenal.perform("espiral")
	else:
		_actions_since_spiral += 1
		var was_melee = arsenal.is_melee(arsenal.current_id)
		await arsenal.perform(arsenal.current_id)
		if phase >= 3 and was_melee and serial == _action_serial and not is_dying:
			await arsenal.perform_follow_up()
		_attacks_left -= 1
	if serial != _action_serial or is_dying: return
	state = State.NEUTRAL
	_attack_mobility = 0.0
	_action_timer = randf_range(action_delay_min, action_delay_max) / _pace

func _swap_weapon() -> void:
	arsenal.equip(_choose_next_weapon())
	play_sfx("equip")
	_attacks_left = randi_range(attacks_per_weapon.x, attacks_per_weapon.y)
	await get_tree().create_timer(0.35, false).timeout

# Elige arma según la distancia, la fase y si hay clon (el original presiona
# cuerpo a cuerpo mientras el clon cubre a distancia). Nunca repite la anterior.
func _choose_next_weapon() -> String:
	var pool = arsenal.available_weapons(phase, is_clone)
	if pool.size() > 1:
		pool.erase(arsenal.current_id)
	var dist = distance_to_target()
	var weights: Array[float] = []
	for id in pool:
		weights.append(_weapon_weight(id, dist))
	return _weighted_pick(pool, weights)

func _weapon_weight(id: String, dist: float) -> float:
	var melee = arsenal.is_melee(id)
	var w = 1.0
	if melee:
		w = 2.0 if dist < 150.0 else 0.9
		if _has_living_clones():
			w *= 2.0
	else:
		w = 1.5 if dist > 170.0 else 1.0
	return w

func _weighted_pick(items: Array[String], weights: Array[float]) -> String:
	var total = 0.0
	for w in weights:
		total += w
	var roll = randf() * total
	for i in range(items.size()):
		roll -= weights[i]
		if roll <= 0.0:
			return items[i]
	return items[items.size() - 1]

func _should_cast_spiral() -> bool:
	return phase >= 3 and not is_clone and _actions_since_spiral >= 4

## Lo consulta el arsenal: si cambió la fase o murió, el ataque en curso se corta.
func is_attack_cancelled() -> bool:
	return is_dying or state == State.TRANSITION or state == State.INTRO

func set_attack_mobility(value: float) -> void:
	_attack_mobility = value

# --- Dash, estocada y salto (los usa el arsenal y la esquiva) ---

## Dash en línea recta. Devuelve la señal de fin para poder esperarlo.
func dash(direction: Vector2, distance: float, invulnerable: bool) -> Signal:
	var dir = direction.normalized()
	var travel = _clamp_travel(dir, minf(distance, max_dash_distance))
	var duration = maxf(travel / dash_speed, 0.05)
	_dash_velocity = dir * dash_speed
	_dash_time_left = duration
	_dash_invulnerable = invulnerable
	_facing = dir
	_ghost_timer = 0.0
	play_sfx("dash")
	return get_tree().create_timer(duration, false).timeout

func dash_towards_target(stop_distance: float) -> void:
	if not target: return
	var to_target = target.global_position - global_position
	var travel = to_target.length() - stop_distance
	if travel < 12.0: return
	await dash(to_target, travel, false)

func lunge(angle: float, distance: float) -> void:
	await dash(Vector2.from_angle(angle), distance, false)

## Salto con arco (sin colisión ni daño mientras está en el aire).
func leap_to(pos: Vector2, duration: float) -> void:
	_is_airborne = true
	_dash_time_left = 0.0
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	play_sfx("dash")
	var start = global_position
	var t = create_tween().set_parallel(true)
	t.tween_method(func(k: float): global_position = start.lerp(pos, k), 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if sprite:
		var base_y = sprite.position.y
		var arc = create_tween()
		arc.tween_property(sprite, "position:y", base_y - 36.0, duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		arc.tween_property(sprite, "position:y", base_y, duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	_is_airborne = false

func _clamp_travel(dir: Vector2, distance: float) -> float:
	var hit = _ray_hit(global_position, global_position + dir * distance)
	if hit != Vector2.INF:
		distance = maxf(0.0, global_position.distance_to(hit) - 22.0)
	var end = clamp_to_arena(global_position + dir * distance)
	return global_position.distance_to(end)

func clamp_to_arena(pos: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, home_position.x - arena_half_extents.x, home_position.x + arena_half_extents.x),
		clampf(pos.y, home_position.y - arena_half_extents.y, home_position.y + arena_half_extents.y))

func arena_center() -> Vector2:
	return home_position

# --- Esquiva de balas ---

func _build_threat_sensor() -> void:
	var sensor = Area2D.new()
	sensor.name = "ThreatSensor"
	sensor.collision_layer = 0
	sensor.collision_mask = 8 # capa de proyectiles
	sensor.monitorable = false
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 120.0
	shape.shape = circle
	sensor.add_child(shape)
	add_child(sensor)
	sensor.area_entered.connect(_on_threat_entered)

func _on_threat_entered(area: Area2D) -> void:
	if not _can_dodge(): return
	if not area is Projectile or area.target_group != "enemy": return
	var to_me = global_position - area.global_position
	if area.direction.dot(to_me.normalized()) < 0.85: return # no viene hacia mí
	if randf() > dodge_chance: return
	_dodge_from(area.direction)

func _can_dodge() -> bool:
	return state == State.NEUTRAL and _dodge_cd <= 0.0 and _dash_time_left <= 0.0 and not _is_airborne and not is_dying

# Se corre de costado (al lado con más espacio), con invulnerabilidad corta.
func _dodge_from(bullet_dir: Vector2) -> void:
	_dodge_cd = dodge_cooldown
	var side = bullet_dir.orthogonal()
	if _is_blocked(side):
		side = -side
	elif not _is_blocked(-side) and randf() < 0.5:
		side = -side
	dash(side, dodge_distance, true)

# --- Visual: animación del sprite de Lázaro, estela y aura ---

func _update_visuals() -> void:
	if target and is_instance_valid(target) and _dash_time_left <= 0.0:
		_facing = (target.global_position - global_position).normalized()
		if arsenal:
			arsenal.track(target.global_position)
	_play_body_animation()

func _play_body_animation() -> void:
	if not sprite or not sprite.sprite_frames: return
	var dir_name = _dir_to_name(_facing)
	var anim = ""
	if _dash_time_left > 0.0 or _is_airborne:
		anim = "Dash_" + _dash_suffix(dir_name)
	elif velocity.length() > 30.0:
		anim = ("run_diagonal_" if _is_diagonal(dir_name) else "run_") + dir_name
	else:
		anim = ("idle_diagonal_" if _is_diagonal(dir_name) else "idle_") + dir_name
	if sprite.sprite_frames.has_animation(anim) and sprite.animation != anim:
		sprite.play(anim)

func _dir_to_name(dir: Vector2) -> String:
	var names = ["right", "down_right", "down", "down_left", "left", "up_left", "up", "up_right"]
	var index = int(round(dir.angle() / (PI / 4.0))) % 8
	if index < 0:
		index += 8
	return names[index]

func _is_diagonal(dir_name: String) -> bool:
	return dir_name in ["up_left", "up_right", "down_left", "down_right"]

func _dash_suffix(dir_name: String) -> String:
	match dir_name:
		"down_left": return "left_down"
		"up_left": return "left_up"
		"down_right": return "right_down"
		"up_right": return "right_up"
	return dir_name

func _update_dash_ghosts(delta: float) -> void:
	if _dash_time_left <= 0.0 and not _is_airborne: return
	_ghost_timer -= delta
	if _ghost_timer > 0.0: return
	_ghost_timer = 0.05
	_spawn_ghost()

func _spawn_ghost() -> void:
	if not sprite or not sprite.sprite_frames: return
	var tex = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if not tex: return
	var ghost = Sprite2D.new()
	ghost.texture = tex
	ghost.scale = sprite.scale
	ghost.z_as_relative = false
	ghost.z_index = maxi(1, z_index - 1)
	ghost.modulate = Color(0.75, 0.08, 0.3, 0.55)
	get_tree().current_scene.add_child(ghost)
	ghost.global_position = sprite.global_position
	var t = ghost.create_tween()
	t.tween_property(ghost, "modulate:a", 0.0, 0.3)
	t.tween_callback(ghost.queue_free)

# Humo oscuro que sube del cuerpo: que se lea como una sombra viva.
func _build_shadow_aura() -> void:
	var p = CPUParticles2D.new()
	p.name = "ShadowAura"
	p.amount = 18
	p.lifetime = 1.1
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(14, 26)
	p.direction = Vector2.UP
	p.spread = 20.0
	p.gravity = Vector2(0, -30)
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 22.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	var g = Gradient.new()
	g.set_color(0, Color(0.25, 0.05, 0.2, 0.55))
	g.set_color(1, Color(0.05, 0.0, 0.05, 0.0))
	p.color_ramp = g
	p.show_behind_parent = true
	add_child(p)

# --- Intro, fases y clon ---

# Cinemática de entrada (ver PrometeoIntro). La barra de vida aparece recién
# cuando termina, como arranque de la pelea.
func _play_intro() -> void:
	state = State.INTRO
	var intro = PrometeoIntro.new()
	add_child(intro)
	await intro.play(self, intro_delay, intro_subtitle)
	if is_dying: return
	_connect_to_hud()
	state = State.NEUTRAL
	_action_timer = 0.6

func _apply_phase_stats() -> void:
	var pace_by_phase = [1.0, 1.0, 1.15, 1.3]
	var dodge_by_phase = [0.35, 0.35, 0.5, 0.65]
	var lead_by_phase = [0.6, 0.6, 0.75, 0.85]
	_pace = pace_by_phase[phase]
	dodge_chance = dodge_by_phase[phase]
	aim_lead = lead_by_phase[phase]
	if arsenal:
		arsenal.fire_rate_mult = _pace
		arsenal.damage_mult = 0.75 if is_clone else 1.0
	if is_clone:
		action_delay_min = 1.4
		action_delay_max = 2.2

func _check_phase_change() -> void:
	if is_clone or is_dying or state == State.TRANSITION: return
	var ratio = float(current_health) / float(max_health)
	if phase == 1 and ratio <= phase_two_threshold:
		_enter_phase(2)
	elif phase == 2 and ratio <= phase_three_threshold:
		_enter_phase(3)

func _enter_phase(new_phase: int) -> void:
	phase = new_phase
	_action_serial += 1
	state = State.TRANSITION
	is_transitioning_phase = true
	_dash_time_left = 0.0
	velocity = Vector2.ZERO
	arsenal.stop_all()
	_clear_bullets()
	play_sfx("roar")
	shake(18.0, 1.0)
	_flash_sprite(Color(2.2, 0.3, 0.5))
	if new_phase == 2:
		_show_title("FASE 2", "", Color(0.75, 0.4, 1.0))
	else:
		_show_title("FASE 3", "", Color(1.0, 0.45, 0.1))
		_dissolve_all_clones()
	_swap_phase_music(new_phase)
	await get_tree().create_timer(2.0, false).timeout
	if is_dying: return
	_apply_phase_stats()
	if new_phase == 2:
		await _split_clone()
		if is_dying: return
	if new_phase == 3:
		_start_ember_aura()
	is_transitioning_phase = false
	_attacks_left = 0 # arranca la fase con un arma nueva
	state = State.NEUTRAL
	_action_timer = 0.4

func _split_clone() -> void:
	var scene = load(scene_file_path if scene_file_path != "" else SELF_SCENE_PATH) as PackedScene
	if not scene: return
	var clone = scene.instantiate()
	clone.is_clone = true
	clone.clone_owner = self
	clone.boss_max_health = maxi(1, int(float(max_health) * clone_health_ratio))
	clone.home_position = home_position
	clone.arena_half_extents = arena_half_extents
	clone.phase = 2
	get_parent().add_child(clone)
	clone.global_position = global_position
	_clones.append(clone)
	play_sfx("teleport")
	await clone.begin_as_clone(_clone_destination(), clone_lifetime)

func _clone_destination() -> Vector2:
	if not target: return clamp_to_arena(global_position + Vector2(160, 0))
	var mirrored = target.global_position + (target.global_position - global_position).normalized() * 170.0
	return clamp_to_arena(mirrored)

## Lo llama el original: el clon sale de su cuerpo hasta su lugar y arranca.
func begin_as_clone(destination: Vector2, lifetime: float) -> void:
	home_position = clone_owner.home_position if clone_owner else home_position
	state = State.INTRO
	if sprite:
		sprite.modulate = Color(0.45, 0.25, 0.75, 0.8)
		_default_modulate = sprite.modulate
	var t = create_tween()
	t.tween_property(self, "global_position", destination, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await t.finished
	if is_dying: return
	state = State.NEUTRAL
	_action_timer = 0.8
	get_tree().create_timer(lifetime, false).timeout.connect(dissolve_clone)

## El clon se desarma en humo (por tiempo, cambio de fase o muerte del original).
func dissolve_clone() -> void:
	if is_dying or not is_inside_tree(): return
	is_dying = true
	_action_serial += 1
	if arsenal:
		arsenal.stop_all()
	_disable_physics()
	_hide_health_bar()
	play_sfx("teleport")
	var t = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.5)
	t.tween_callback(queue_free)

func _dissolve_all_clones() -> void:
	for c in _clones:
		if is_instance_valid(c) and c.has_method("dissolve_clone"):
			c.dissolve_clone()
	_clones.clear()

func _has_living_clones() -> bool:
	for c in _clones:
		if is_instance_valid(c) and not c.is_dying:
			return true
	return false

func _clear_bullets() -> void:
	for b in get_tree().get_nodes_in_group("prometeo_bullet"):
		if b.has_method("dissolve"):
			b.dissolve()

func _start_ember_aura() -> void:
	var p = CPUParticles2D.new()
	p.name = "EmberAura"
	p.amount = 24
	p.lifetime = 0.9
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(16, 28)
	p.direction = Vector2.UP
	p.spread = 35.0
	p.gravity = Vector2(0, -60)
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 50.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	var g = Gradient.new()
	g.set_color(0, Color(1.0, 0.7, 0.2, 1.0))
	g.set_color(1, Color(1.0, 0.1, 0.0, 0.0))
	p.color_ramp = g
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	add_child(p)

# --- Daño ---

func take_damage(amount: int, is_crit: bool = false) -> void:
	if _is_invulnerable():
		_show_floating_text("ESQUIVA" if _dash_invulnerable else "INMUNE")
		return
	super.take_damage(amount, is_crit)
	hit_stun_timer = 0.0 # los golpes no lo frenan
	_update_hud_health()
	_check_phase_change()

func _is_invulnerable() -> bool:
	if state == State.INTRO or state == State.TRANSITION: return true
	if _is_airborne: return true
	return _dash_time_left > 0.0 and _dash_invulnerable

## Daño al jugador centralizado (no pega durante transiciones).
func deal_damage_to_target(amount: int) -> void:
	if is_attack_cancelled(): return
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(amount, boss_display_name, global_position)

func distance_to_target() -> float:
	if not target or not is_instance_valid(target): return 9999.0
	return global_position.distance_to(target.global_position)

## Dónde va a estar el jugador dentro de "seconds" (para apuntar adelantado).
func predict_target_position(seconds: float) -> Vector2:
	if not target or not is_instance_valid(target): return global_position
	var vel = target.velocity if "velocity" in target else Vector2.ZERO
	return target.global_position + vel * seconds

func die() -> void:
	if is_dying: return
	_action_serial += 1
	if arsenal:
		arsenal.stop_all()
		arsenal.hide_weapon()
	_stop_auras()
	if not is_clone:
		_dissolve_all_clones()
		_clear_bullets()
		_hide_hud_health()
	super.die()

func _stop_auras() -> void:
	for aura_name in ["ShadowAura", "EmberAura"]:
		var aura = get_node_or_null(aura_name) as CPUParticles2D
		if aura:
			aura.emitting = false

# Muerte: se deshace en humo y brasas. Se libera más tarde para que ningún
# ataque en curso quede esperando sobre un nodo borrado.
func _play_death_fx() -> void:
	var burst = CPUParticles2D.new()
	burst.one_shot = true
	burst.explosiveness = 0.9
	burst.amount = 60
	burst.lifetime = 1.4
	burst.spread = 180.0
	burst.gravity = Vector2(0, -40)
	burst.initial_velocity_min = 40.0
	burst.initial_velocity_max = 160.0
	burst.scale_amount_min = 3.0
	burst.scale_amount_max = 7.0
	var g = Gradient.new()
	g.set_color(0, Color(1.0, 0.4, 0.2, 1.0))
	g.set_color(1, Color(0.1, 0.0, 0.1, 0.0))
	burst.color_ramp = g
	add_child(burst)
	burst.emitting = true
	if not is_clone:
		shake(22.0, 1.2)
	get_tree().create_timer(3.0, false).timeout.connect(queue_free)

# --- Sonido, cámara y textos ---

func _collect_sounds() -> void:
	for child in get_children():
		if child is AudioStreamPlayer2D:
			child.bus = "SFX"
			_sounds[String(child.name).trim_suffix("_sound").to_lower()] = child

func play_sfx(sfx_name: String) -> void:
	var player = _sounds.get(sfx_name) as AudioStreamPlayer2D
	if player:
		player.play()

func shake(force: float, duration: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_custom_camera_shake"):
		player.apply_custom_camera_shake(force, duration)

## Color normal del cuerpo (la sombra), para volver a él después de un efecto.
func sprite_base_modulate() -> Color:
	return _default_modulate

func flash(color: Color) -> void:
	_flash_sprite(color)

func _flash_sprite(color: Color) -> void:
	if not sprite: return
	var t = create_tween()
	t.tween_property(sprite, "modulate", color, 0.15)
	t.tween_property(sprite, "modulate", _default_modulate, 0.8)

func _show_floating_text(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.8, 0.7, 1.0))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.position = Vector2(-30, -70)
	add_child(label)
	var t = create_tween().set_parallel(true)
	t.tween_property(label, "position:y", -95.0, 0.5)
	t.tween_property(label, "modulate:a", 0.0, 0.5)
	t.chain().tween_callback(label.queue_free)

func _show_title(title: String, subtitle: String, color: Color) -> void:
	var layer = CanvasLayer.new()
	layer.layer = 100
	get_tree().current_scene.add_child(layer)
	var box = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(box)
	var font_res = load("res://Art/Fonts/Dekatron-SemiBold.otf")
	box.add_child(_make_title_label(title, 46, color, font_res))
	if subtitle != "":
		box.add_child(_make_title_label(subtitle, 20, Color(0.85, 0.85, 0.9), font_res))
	box.modulate.a = 0.0
	var t = create_tween()
	t.tween_property(box, "modulate:a", 1.0, 0.35)
	t.tween_interval(1.3)
	t.tween_property(box, "modulate:a", 0.0, 0.6)
	t.tween_callback(layer.queue_free)

func _make_title_label(text: String, size: int, color: Color, font_res: Font) -> Label:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_res:
		label.add_theme_font_override("font", font_res)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 10)
	return label

# --- Música (nodo Boss_Fight_Music de la sala, como el boss 2) ---

func _swap_phase_music(new_phase: int) -> void:
	var stream = phase_two_music if new_phase == 2 else phase_three_music
	if not stream: return
	var music = _get_boss_music()
	if not music: return
	music.stream = stream
	music.play()

func _get_boss_music() -> AudioStreamPlayer:
	var music = get_parent().get_node_or_null("Boss_Fight_Music") if get_parent() else null
	if not music:
		music = get_tree().current_scene.get_node_or_null("Boss_Fight_Music")
	return music as AudioStreamPlayer

# --- Barra grande de vida ---

func _connect_to_hud() -> void:
	var created = BossBarHelper.create(get_tree(), boss_display_name, max_health, current_health)
	_bar_instance = created.get("instance")
	_bar = created.get("bar")

func _update_hud_health() -> void:
	if not _bar: return
	create_tween().tween_property(_bar, "value", float(maxi(0, current_health)), 0.2)

func _hide_hud_health() -> void:
	if _bar_instance and is_instance_valid(_bar_instance):
		_bar_instance.queue_free()
	_bar_instance = null
	_bar = null
