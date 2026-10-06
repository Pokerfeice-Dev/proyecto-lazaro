extends Node2D
class_name PrometeoArsenal

## Arsenal de Prometeo (boss 3): las mismas armas que fue juntando el jugador,
## usadas en su contra. Cada ataque es una corrutina (se espera con await) y
## siempre avisa antes de pegar: línea naranja = disparo, abanico/círculo
## rojo = golpe. Los avisos son cortos y se encadenan, para que la pelea sea
## de esquivar y sobrevivir, no de recibir golpes sin chance.
##
## El boss (padre) decide cuándo atacar y con qué arma; el arsenal resuelve
## cómo se ejecuta cada ataque y le pide al boss los movimientos (dash, estocada,
## salto) cuando el arma los necesita.

signal weapon_changed(weapon_id: String)

const BULLET_SCENE := preload("res://Scenes/Enemies/prometeo_projectile.tscn")

const TINT_BULLET := Color(1.0, 0.35, 0.35)
const TINT_PELLET := Color(1.0, 0.6, 0.3)
const TINT_HEAVY := Color(1.4, 0.25, 0.6)
const TINT_BEE := Color(1.3, 1.1, 0.25)
const TINT_FIRE := Color(1.4, 0.6, 0.15)

## Armas del jugador que Prometeo sabe usar. "phase" = desde qué fase la saca.
const WEAPONS := {
	"pistola": {"melee": false, "range": 220.0, "phase": 1, "texture": "res://Art/Weapons/Distance/Pistol/Weapon_Pisotol.png"},
	"escopeta": {"melee": false, "range": 120.0, "phase": 1, "texture": "res://Art/Weapons/Distance/Shotgun/Weapon_Shotgun.png"},
	"uzi": {"melee": false, "range": 190.0, "phase": 1, "texture": "res://Art/Weapons/Distance/Uzi/Weapon_Uzi.png"},
	"hacha": {"melee": true, "range": 70.0, "phase": 1, "texture": "res://Art/Weapons/Melee/Axe/Weapon_Axe.png"},
	"daga": {"melee": true, "range": 90.0, "phase": 1, "texture": "res://Art/Weapons/Melee/Dagger/Weapon_Dagger.png"},
	"minigun": {"melee": false, "range": 230.0, "phase": 2, "texture": "res://Art/Weapons/Distance/Uzi/Weapon_Uzi.png"},
	"lanzallamas": {"melee": false, "range": 95.0, "phase": 2, "texture": "res://Art/Weapons/Distance/Shotgun/Weapon_Shotgun.png"},
	"colmena": {"melee": false, "range": 210.0, "phase": 2, "texture": "res://Art/Weapons/Distance/Pistol/HiveMindPistol/synergy_hivemind_sprite.png"},
	"maza": {"melee": true, "range": 110.0, "phase": 2, "texture": "res://Art/Weapons/Melee/Mace/Weapon_Mace.png"},
}

## El clon solo dispara: el original es el que presiona cuerpo a cuerpo.
const CLONE_WEAPONS: Array[String] = ["pistola", "uzi", "colmena", "minigun"]

const WEAPON_ORBIT := 26.0
const MUZZLE_DISTANCE := 38.0

var boss: Node2D = null
var current_id: String = "pistola"
var damage_mult: float = 1.0
var fire_rate_mult: float = 1.0
var aim_angle: float = 0.0
var aim_locked: bool = false

var _weapon_sprite: Sprite2D
var _flame_cone: PrometeoFlameCone
var _textures: Dictionary = {}

func _ready() -> void:
	_weapon_sprite = _build_weapon_sprite()
	add_child(_weapon_sprite)
	_flame_cone = PrometeoFlameCone.new()
	add_child(_flame_cone)

func setup(p_boss: Node2D) -> void:
	boss = p_boss
	equip(current_id, false)

# --- Consultas que usa el cerebro del boss ---

func available_weapons(phase: int, ranged_only: bool) -> Array[String]:
	var result: Array[String] = []
	for id in WEAPONS.keys():
		if WEAPONS[id].phase > phase: continue
		if ranged_only and not CLONE_WEAPONS.has(id): continue
		result.append(id)
	return result

func is_melee(id: String) -> bool:
	return WEAPONS.has(id) and WEAPONS[id].melee

func preferred_range(id: String) -> float:
	return WEAPONS[id].range if WEAPONS.has(id) else 180.0

# --- Arma en mano ---

func equip(id: String, flourish: bool = true) -> void:
	if not WEAPONS.has(id): return
	current_id = id
	_weapon_sprite.texture = _get_texture(id)
	weapon_changed.emit(id)
	if flourish:
		_play_equip_flourish()

## Apunta el arma (fuera de los ataques el boss apunta siempre al jugador).
func track(world_pos: Vector2) -> void:
	if aim_locked: return
	aim_angle = (world_pos - global_position).angle()

func _process(_delta: float) -> void:
	_update_weapon_transform()

func _update_weapon_transform() -> void:
	var dir = Vector2.from_angle(aim_angle)
	_weapon_sprite.position = dir * WEAPON_ORBIT
	_weapon_sprite.rotation = aim_angle
	_weapon_sprite.flip_v = dir.x < 0.0
	_weapon_sprite.z_index = -1 if dir.y < -0.3 else 1
	_flame_cone.position = dir * MUZZLE_DISTANCE
	_flame_cone.rotation = aim_angle

func hide_weapon() -> void:
	_weapon_sprite.hide()

## Corta cualquier ataque en curso (cambio de fase, muerte).
func stop_all() -> void:
	aim_locked = false
	if _flame_cone:
		_flame_cone.stop()
	if is_inside_tree():
		for t in get_tree().get_nodes_in_group("prometeo_telegraph"):
			t.queue_free()

# --- Ejecución de ataques ---

func perform(id: String) -> void:
	if _cancelled(): return
	aim_locked = true
	match id:
		"pistola": await _attack_pistola()
		"escopeta": await _attack_escopeta()
		"uzi": await _attack_uzi()
		"minigun": await _attack_minigun()
		"lanzallamas": await _attack_lanzallamas()
		"colmena": await _attack_colmena()
		"hacha": await _attack_hacha()
		"daga": await _attack_daga()
		"maza": await _attack_maza()
		"espiral": await _attack_espiral()
	aim_locked = false

## Fase 3: después de un golpe cuerpo a cuerpo remata con un escopetazo rápido
## sin cambiar de arma ("doble arma", como el jugador con dos armas equipadas).
func perform_follow_up() -> void:
	if _cancelled(): return
	aim_locked = true
	var previous = current_id
	_weapon_sprite.texture = _get_texture("escopeta")
	_aim_at_target(0.0)
	PrometeoTelegraph.arc(_scene_root(), _muzzle(), aim_angle, 120.0, deg_to_rad(22.0), 0.22, PrometeoTelegraph.COLOR_RANGED)
	await _wait(0.22)
	if not _cancelled():
		_fire_fan(5, deg_to_rad(40.0), 300.0, 340.0, TINT_PELLET)
		boss.play_sfx("shotgun")
	await _wait(0.2)
	_weapon_sprite.texture = _get_texture(previous)
	aim_locked = false

# Pistola: tiros precisos que apuntan a donde va a estar el jugador.
func _attack_pistola() -> void:
	var shots = 2 + boss.phase
	_aim_at_target(0.0)
	await _aim_warning(0.3, 260.0)
	for i in range(shots):
		if _cancelled(): return
		var speed = 360.0
		_aim_at_target(_lead_time(speed))
		_fire_bullet(aim_angle, speed, TINT_BULLET)
		boss.play_sfx("shot")
		await _wait(0.3 / fire_rate_mult)
	await _wait(0.2)

# Escopeta: se mete cerca con un dash y suelta perdigones en abanico.
func _attack_escopeta() -> void:
	if boss.distance_to_target() > 150.0:
		await boss.dash_towards_target(95.0)
	var volleys = 3 if boss.phase >= 3 else 2
	for v in range(volleys):
		if _cancelled(): return
		_aim_at_target(0.0)
		PrometeoTelegraph.arc(_scene_root(), _muzzle(), aim_angle, 150.0, deg_to_rad(24.0), 0.3, PrometeoTelegraph.COLOR_RANGED)
		await _wait(0.3)
		if _cancelled(): return
		_fire_fan(6, deg_to_rad(48.0), 260.0, 340.0, TINT_PELLET)
		boss.play_sfx("shotgun")
		await _wait(0.25 / fire_rate_mult)

# Uzi: ráfaga larga y desprolija mientras sigue moviéndose alrededor tuyo.
func _attack_uzi() -> void:
	boss.set_attack_mobility(0.85)
	_aim_at_target(0.0)
	await _aim_warning(0.22, 220.0)
	var bullets = 12 + 2 * boss.phase
	for i in range(bullets):
		if _cancelled(): break
		_aim_at_target(_lead_time(390.0) * 0.5)
		_fire_bullet(aim_angle + randf_range(-0.13, 0.13), 390.0, TINT_BULLET)
		boss.play_sfx("shot")
		await _wait(0.075 / fire_rate_mult)
	boss.set_attack_mobility(0.0)
	await _wait(0.2)

# Minigun: se planta, la mira (línea) te sigue mientras gira y después barre
# con una lluvia de balas que gira más lento de lo que corrés.
func _attack_minigun() -> void:
	boss.set_attack_mobility(0.0)
	_aim_at_target(0.0)
	var warning = PrometeoTelegraph.line(_scene_root(), _muzzle(), aim_angle, 320.0, 0.8, PrometeoTelegraph.COLOR_RANGED)
	boss.play_sfx("laser")
	var spin = 0.0
	while spin < 0.8:
		if _cancelled(): return
		_turn_aim_towards_target(2.5, 0.05)
		if is_instance_valid(warning):
			warning.global_position = _muzzle()
			warning.rotation = aim_angle
		spin += 0.05
		await _wait(0.05)
	var turn_rate = 1.3 + 0.35 * float(boss.phase - 2)
	var elapsed = 0.0
	while elapsed < 1.8:
		if _cancelled(): return
		_turn_aim_towards_target(turn_rate, 0.05)
		_fire_bullet(aim_angle + randf_range(-0.05, 0.05), 360.0, TINT_HEAVY)
		if int(elapsed * 20.0) % 2 == 0:
			boss.play_sfx("shot")
		elapsed += 0.05
		await _wait(0.05)
	await _wait(0.3)

# Lanzallamas: se acerca, avisa con el abanico y te persigue con el fuego.
func _attack_lanzallamas() -> void:
	if boss.distance_to_target() > 120.0:
		await boss.dash_towards_target(80.0)
	_aim_at_target(0.0)
	PrometeoTelegraph.arc(_scene_root(), _muzzle(), aim_angle, _flame_cone.reach, deg_to_rad(_flame_cone.half_angle_degrees), 0.45, PrometeoTelegraph.COLOR_RANGED)
	await _wait(0.45)
	if _cancelled(): return
	_flame_cone.start(_scaled(boss.bullet_damage * 0.6), boss.boss_display_name)
	boss.play_sfx("flame")
	boss.set_attack_mobility(0.35)
	var elapsed = 0.0
	while elapsed < 2.2:
		if _cancelled(): break
		_turn_aim_towards_target(1.3, 0.05)
		elapsed += 0.05
		await _wait(0.05)
	_flame_cone.stop()
	boss.set_attack_mobility(0.0)
	await _wait(0.3)

# Colmena: suelta abejas que doblan hacia vos un rato y después siguen derecho.
func _attack_colmena() -> void:
	_aim_at_target(0.0)
	await _aim_warning(0.35, 160.0)
	if _cancelled(): return
	var count = 7 if boss.phase >= 3 else 5
	var spread = deg_to_rad(80.0)
	for i in range(count):
		var t = 0.5 if count == 1 else float(i) / float(count - 1)
		var angle = aim_angle - spread * 0.5 + spread * t
		_fire_bullet(angle, 170.0, TINT_BEE, 4.5, 2.4, 1.8)
	boss.play_sfx("shot")
	await _wait(0.6)

# Hacha: se acerca, marca un abanico amplio y hachazo (doble en fase 3).
func _attack_hacha() -> void:
	if boss.distance_to_target() > 95.0:
		await boss.dash_towards_target(60.0)
	var swings = 2 if boss.phase >= 3 else 1
	for s in range(swings):
		if _cancelled(): return
		_aim_at_target(0.0)
		var center = boss.global_position
		PrometeoTelegraph.arc(_scene_root(), center, aim_angle, 100.0, deg_to_rad(75.0), 0.42, PrometeoTelegraph.COLOR_MELEE)
		await _wait(0.42)
		if _cancelled(): return
		await boss.lunge(aim_angle, 40.0)
		_slash_flash(boss.global_position, aim_angle, 105.0, deg_to_rad(80.0))
		_hit_target_in_arc(boss.global_position, aim_angle, 105.0, deg_to_rad(80.0), boss.melee_damage)
		boss.play_sfx("slash")
		await _wait(0.22)
	await _wait(0.3)

# Daga: estocadas rápidas en cadena, cada una con su línea de aviso.
func _attack_daga() -> void:
	var stabs = 4 if boss.phase >= 3 else 3
	for i in range(stabs):
		if _cancelled(): return
		_aim_at_target(0.25)
		var reach = clampf(boss.distance_to_target() + 30.0, 70.0, 150.0)
		PrometeoTelegraph.line(_scene_root(), boss.global_position, aim_angle, reach, 0.24, PrometeoTelegraph.COLOR_MELEE)
		await _wait(0.24)
		if _cancelled(): return
		var start = boss.global_position
		await boss.lunge(aim_angle, reach)
		_hit_target_near_segment(start, boss.global_position, 30.0, int(boss.melee_damage * 0.8))
		boss.play_sfx("slash")
		await _wait(0.16)
	await _wait(0.3)

# Maza: salto a donde vas a estar, aplastón con onda (y anillo de balas desde la fase 2).
func _attack_maza() -> void:
	var landing = boss.clamp_to_arena(boss.predict_target_position(0.45))
	PrometeoTelegraph.circle(_scene_root(), landing, 105.0, 0.7, PrometeoTelegraph.COLOR_MELEE)
	await boss.leap_to(landing, 0.7)
	if _cancelled(): return
	boss.play_sfx("slam")
	boss.shake(14.0, 0.3)
	_spawn_shockwave(landing, 110.0)
	_hit_target_in_radius(landing, 105.0, int(boss.melee_damage * 1.2))
	var ring = 16 if boss.phase >= 3 else 10
	for i in range(ring):
		_fire_bullet(TAU / float(ring) * i, 200.0, TINT_HEAVY, 3.0, 0.0, 0.0, landing)
	await _wait(0.45)

# Fase 3, "El fuego robado": vuelve al centro y gira espirales de fuego.
# Hay huecos entre los brazos para pasar caminando.
func _attack_espiral() -> void:
	await boss.leap_to(boss.arena_center(), 0.6)
	if _cancelled(): return
	PrometeoTelegraph.circle(_scene_root(), boss.global_position, 60.0, 0.5, PrometeoTelegraph.COLOR_RANGED)
	boss.play_sfx("roar")
	await _wait(0.5)
	var base = randf() * TAU
	var arms = 3
	var elapsed = 0.0
	while elapsed < 4.0:
		if _cancelled(): return
		for a in range(arms):
			_fire_bullet(base + TAU / float(arms) * a, 165.0, TINT_FIRE, 5.0, 0.0, 0.0, boss.global_position)
		base += 0.21
		if int(elapsed * 10.0) % 3 == 0:
			boss.play_sfx("shot")
		elapsed += 0.09
		await _wait(0.09)
	await _wait(0.4)

# --- Ayudas de puntería ---

func _aim_at_target(lead: float) -> void:
	if not boss.target: return
	aim_angle = (boss.predict_target_position(lead) - _muzzle()).angle()

func _turn_aim_towards_target(rate: float, dt: float) -> void:
	if not boss.target: return
	var desired = (boss.target.global_position - _muzzle()).angle()
	var diff = wrapf(desired - aim_angle, -PI, PI)
	aim_angle += clampf(diff, -rate * dt, rate * dt)

func _lead_time(bullet_speed: float) -> float:
	return boss.distance_to_target() / maxf(bullet_speed, 1.0) * boss.aim_lead

func _aim_warning(duration: float, length: float) -> void:
	PrometeoTelegraph.line(_scene_root(), _muzzle(), aim_angle, length, duration, PrometeoTelegraph.COLOR_RANGED)
	await _wait(duration)

# --- Disparo ---

func _fire_bullet(angle: float, speed: float, tint: Color, p_lifetime: float = 4.0, turn_rate: float = 0.0, homing_time: float = 0.0, origin: Vector2 = Vector2.INF) -> void:
	var bullet = BULLET_SCENE.instantiate()
	bullet.configure(speed, tint, p_lifetime, turn_rate, homing_time)
	bullet.source_name = boss.boss_display_name
	_scene_root().add_child(bullet)
	bullet.global_position = _muzzle() if origin == Vector2.INF else origin
	bullet.setup(Vector2.from_angle(angle), _scaled(boss.bullet_damage), "player")

func _fire_fan(count: int, spread: float, speed_min: float, speed_max: float, tint: Color) -> void:
	for i in range(count):
		var t = 0.5 if count == 1 else float(i) / float(count - 1)
		var angle = aim_angle - spread * 0.5 + spread * t + randf_range(-0.04, 0.04)
		_fire_bullet(angle, randf_range(speed_min, speed_max), tint, 1.2)

func _muzzle() -> Vector2:
	return global_position + Vector2.from_angle(aim_angle) * MUZZLE_DISTANCE

func _scaled(value: float) -> int:
	return maxi(1, int(value * damage_mult))

# --- Golpes cuerpo a cuerpo ---

func _hit_target_in_arc(origin: Vector2, angle: float, radius: float, half_angle: float, dmg: float) -> void:
	if not boss.target: return
	var to_target = boss.target.global_position - origin
	if to_target.length() > radius: return
	if absf(wrapf(to_target.angle() - angle, -PI, PI)) > half_angle: return
	boss.deal_damage_to_target(_scaled(dmg))

func _hit_target_near_segment(a: Vector2, b: Vector2, width: float, dmg: float) -> void:
	if not boss.target: return
	var closest = Geometry2D.get_closest_point_to_segment(boss.target.global_position, a, b)
	if closest.distance_to(boss.target.global_position) <= width:
		boss.deal_damage_to_target(_scaled(dmg))

func _hit_target_in_radius(origin: Vector2, radius: float, dmg: float) -> void:
	if not boss.target: return
	if boss.target.global_position.distance_to(origin) <= radius:
		boss.deal_damage_to_target(_scaled(dmg))

# --- Efectos ---

func _slash_flash(center: Vector2, angle: float, radius: float, half_angle: float) -> void:
	PrometeoTelegraph.arc(_scene_root(), center, angle, radius, half_angle, 0.12, PrometeoTelegraph.COLOR_SLASH)

func _spawn_shockwave(pos: Vector2, radius: float) -> void:
	var wave = FuriaShockwave.new()
	wave.max_radius = radius
	wave.set_meta("color_fill", Color(0.5, 0.05, 0.2, 0.35))
	wave.set_meta("color_stroke", Color(1.0, 0.2, 0.4, 0.8))
	_scene_root().add_child(wave)
	wave.global_position = pos

func _play_equip_flourish() -> void:
	_weapon_sprite.scale = Vector2(2.6, 2.6)
	_weapon_sprite.modulate = Color(2.5, 0.6, 0.8)
	var t = create_tween().set_parallel(true)
	t.tween_property(_weapon_sprite, "scale", Vector2(1.9, 1.9), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_weapon_sprite, "modulate", Color(0.55, 0.22, 0.3), 0.35)

func _build_weapon_sprite() -> Sprite2D:
	var s = Sprite2D.new()
	s.name = "WeaponSprite"
	s.scale = Vector2(1.9, 1.9)
	s.modulate = Color(0.55, 0.22, 0.3)
	return s

func _get_texture(id: String) -> Texture2D:
	if not _textures.has(id):
		_textures[id] = load(WEAPONS[id].texture)
	return _textures[id]

# --- Utilidades ---

func _cancelled() -> bool:
	return not is_instance_valid(boss) or not boss.is_inside_tree() or boss.is_attack_cancelled()

func _wait(seconds: float) -> Signal:
	return get_tree().create_timer(maxf(seconds, 0.01), false).timeout

func _scene_root() -> Node:
	return get_tree().current_scene
