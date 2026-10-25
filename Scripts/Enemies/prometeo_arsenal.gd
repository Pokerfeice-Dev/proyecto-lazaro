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
	"pistola": {"melee": false, "range": 220.0, "phase": 1, "scene": "res://Scenes/Weapon/Revolver.tscn"},
	"escopeta": {"melee": false, "range": 120.0, "phase": 1, "scene": "res://Scenes/Weapon/shotgun.tscn"},
	"uzi": {"melee": false, "range": 190.0, "phase": 1, "scene": "res://Scenes/Weapon/uzi.tscn"},
	"hacha": {"melee": true, "range": 70.0, "phase": 1, "scene": "res://Scenes/Weapon/axe.tscn"},
	"daga": {"melee": true, "range": 90.0, "phase": 1, "scene": "res://Scenes/Weapon/dagger.tscn"},
	"minigun": {"melee": false, "range": 230.0, "phase": 2, "scene": "res://Scenes/Weapon/Minigun.tscn"},
	"lanzallamas": {"melee": false, "range": 95.0, "phase": 2, "scene": "res://Scenes/Weapon/Cerberus.tscn"},
	"colmena": {"melee": false, "range": 210.0, "phase": 2, "scene": "res://Scenes/Weapon/HivemindPistol.tscn"},
	"maza": {"melee": true, "range": 110.0, "phase": 2, "scene": "res://Scenes/Weapon/mace.tscn"},
}

## El clon solo dispara: el original es el que presiona cuerpo a cuerpo.
const CLONE_WEAPONS: Array[String] = ["pistola", "uzi", "colmena", "minigun"]

const WEAPON_ORBIT := 26.0
const MUZZLE_DISTANCE := 38.0
@export_group("Armas en mano")
@export var hand_offset := Vector2(0, 8)
@export var hand_orbit := 12.0
@export var weapon_visual_scale := 1.35

var boss: Node2D = null
var current_id: String = "pistola"
var damage_mult: float = 1.0
var fire_rate_mult: float = 1.0
var aim_angle: float = 0.0
var aim_locked: bool = false

var _weapon_sprite: Node2D
var _weapon_pivot: Node2D
var _muzzle_offset := Vector2(MUZZLE_DISTANCE - WEAPON_ORBIT, 0)
var _equip_tween: Tween
var _flame_cone: PrometeoFlameCone
var _run: Dictionary = {}

func _ready() -> void:
	_weapon_pivot = Node2D.new()
	_weapon_pivot.name = "WeaponPivot"
	add_child(_weapon_pivot)
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
	_set_weapon_visual(id)
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
	_weapon_pivot.position = hand_offset + dir * hand_orbit
	_weapon_pivot.rotation = aim_angle
	_weapon_pivot.scale = Vector2(weapon_visual_scale, -weapon_visual_scale if dir.x < 0.0 else weapon_visual_scale)
	_weapon_pivot.z_index = -1 if dir.y < -0.3 else 1
	_flame_cone.position = to_local(_muzzle())
	_flame_cone.rotation = aim_angle

func hide_weapon() -> void:
	_weapon_pivot.hide()

## Corta cualquier ataque en curso (cambio de fase, muerte).
func stop_all() -> void:
	if not _run.is_empty(): _run.cancelled = true
	aim_locked = false
	if _flame_cone:
		_flame_cone.stop()
	if is_inside_tree():
		for indicator in get_children():
			if indicator is PrometeoTelegraph: indicator.queue_free()
	if is_instance_valid(boss): boss.stop_attack_sounds()

# --- Ejecución de ataques ---

func perform(id: String) -> void:
	if _cancelled(): return
	var run := {"cancelled": false}
	_run = run
	aim_locked = true
	match id:
		"pistola": await _attack_pistola(run)
		"escopeta": await _attack_escopeta(run)
		"uzi": await _attack_uzi(run)
		"minigun": await _attack_minigun(run)
		"lanzallamas": await _attack_lanzallamas(run)
		"colmena": await _attack_colmena(run)
		"hacha": await _attack_hacha(run)
		"daga": await _attack_daga(run)
		"maza": await _attack_maza(run)
		"espiral": await _attack_espiral(run)
	if _cancelled(run): return
	aim_locked = false

## Fase 3: después de un golpe cuerpo a cuerpo remata con un escopetazo rápido
## sin cambiar de arma ("doble arma", como el jugador con dos armas equipadas).
func perform_follow_up() -> void:
	if _cancelled(): return
	var run := {"cancelled": false}
	_run = run
	aim_locked = true
	var previous = current_id
	_set_weapon_visual("escopeta")
	_aim_at_target(0.0)
	PrometeoTelegraph.arc(self, _muzzle(), aim_angle, 408.0, deg_to_rad(23.0), 0.3, PrometeoTelegraph.COLOR_RANGED)
	await _wait(0.3)
	if not _cancelled(run):
		_fire_fan(5, deg_to_rad(40.0), 300.0, 340.0, TINT_PELLET)
		boss.play_sfx("shotgun")
	await _wait(0.2)
	if _cancelled(run): return
	_set_weapon_visual(previous)
	aim_locked = false

# Pistola: tiros precisos que apuntan a donde va a estar el jugador.
func _attack_pistola(run: Dictionary) -> void:
	var shots = 2 + boss.phase
	for i in range(shots):
		if _cancelled(run): return
		var speed = 360.0
		_aim_at_target(_lead_time(speed))
		await _aim_warning(0.3 / fire_rate_mult, 360.0)
		if _cancelled(run): return
		_fire_bullet(aim_angle, speed, TINT_BULLET)
		boss.play_sfx("shot")
		await _wait(0.08)
	await _wait(0.2)

# Escopeta: se mete cerca con un dash y suelta perdigones en abanico.
func _attack_escopeta(run: Dictionary) -> void:
	if boss.distance_to_target() > 150.0:
		await boss.dash_towards_target(95.0)
	var volleys = 3 if boss.phase >= 3 else 2
	for v in range(volleys):
		if _cancelled(run): return
		_aim_at_target(0.0)
		PrometeoTelegraph.arc(self, _muzzle(), aim_angle, 408.0, deg_to_rad(27.0), 0.3, PrometeoTelegraph.COLOR_RANGED)
		await _wait(0.3)
		if _cancelled(run): return
		_fire_fan(6, deg_to_rad(48.0), 260.0, 340.0, TINT_PELLET)
		boss.play_sfx("shotgun")
		await _wait(0.25 / fire_rate_mult)

# Uzi: ráfaga larga y desprolija mientras sigue moviéndose alrededor tuyo.
func _attack_uzi(run: Dictionary) -> void:
	boss.set_attack_mobility(0.85)
	_aim_at_target(0.0)
	await _aim_warning(0.22, 220.0)
	var bullets = 12 + 2 * boss.phase
	for i in range(bullets):
		if _cancelled(run): break
		_aim_at_target(_lead_time(390.0) * 0.5)
		_fire_bullet(aim_angle + randf_range(-0.13, 0.13), 390.0, TINT_BULLET)
		boss.play_sfx("shot")
		await _wait(0.075 / fire_rate_mult)
	if _cancelled(run): return
	boss.set_attack_mobility(0.0)
	await _wait(0.2)

# Minigun: se planta, la mira (línea) te sigue mientras gira y después barre
# con una lluvia de balas que gira más lento de lo que corrés.
func _attack_minigun(run: Dictionary) -> void:
	boss.set_attack_mobility(0.0)
	_aim_at_target(0.0)
	var warning = PrometeoTelegraph.line(self, _muzzle(), aim_angle, 320.0, 0.8, PrometeoTelegraph.COLOR_RANGED)
	boss.play_sfx("laser")
	var spin = 0.0
	while spin < 0.8:
		if _cancelled(run): return
		_turn_aim_towards_target(2.5, 0.05)
		if is_instance_valid(warning):
			warning.global_position = _muzzle()
			warning.rotation = aim_angle
		spin += 0.05
		await _wait(0.05)
	var turn_rate = 1.3 + 0.35 * float(boss.phase - 2)
	var elapsed = 0.0
	while elapsed < 1.8:
		if _cancelled(run): return
		_turn_aim_towards_target(turn_rate, 0.05)
		_fire_bullet(aim_angle + randf_range(-0.05, 0.05), 360.0, TINT_HEAVY)
		if int(elapsed * 20.0) % 2 == 0:
			boss.play_sfx("shot")
		elapsed += 0.05
		await _wait(0.05)
	await _wait(0.3)

# Lanzallamas: se acerca, avisa con el abanico y te persigue con el fuego.
func _attack_lanzallamas(run: Dictionary) -> void:
	if boss.distance_to_target() > 120.0:
		await boss.dash_towards_target(80.0)
	if _cancelled(run): return
	_aim_at_target(0.0)
	PrometeoTelegraph.arc(self, _muzzle(), aim_angle, _flame_cone.reach, deg_to_rad(_flame_cone.half_angle_degrees), 0.45, PrometeoTelegraph.COLOR_RANGED)
	await _wait(0.45)
	if _cancelled(run): return
	_flame_cone.start(_scaled(boss.bullet_damage * 0.6), boss.boss_display_name)
	boss.play_sfx("flame")
	boss.set_attack_mobility(0.35)
	var elapsed = 0.0
	while elapsed < 2.2:
		if _cancelled(run): break
		_turn_aim_towards_target(1.3, 0.05)
		boss.energy_fx.shot(_muzzle(), aim_angle)
		elapsed += 0.05
		await _wait(0.05)
	if _cancelled(run): return
	_flame_cone.stop()
	boss.stop_attack_sounds()
	boss.set_attack_mobility(0.0)
	await _wait(0.3)

# Colmena: suelta abejas que doblan hacia vos un rato y después siguen derecho.
func _attack_colmena(run: Dictionary) -> void:
	_aim_at_target(0.0)
	PrometeoTelegraph.arc(self, _muzzle(), aim_angle, 200.0, deg_to_rad(40.0), 0.35, PrometeoTelegraph.COLOR_RANGED)
	await _wait(0.35)
	if _cancelled(run): return
	var count = 7 if boss.phase >= 3 else 5
	var spread = deg_to_rad(80.0)
	for i in range(count):
		var t = 0.5 if count == 1 else float(i) / float(count - 1)
		var angle = aim_angle - spread * 0.5 + spread * t
		_fire_bullet(angle, 170.0, TINT_BEE, 4.5, 2.4, 1.8)
	boss.play_sfx("shot")
	await _wait(0.6)

# Hacha: se acerca, marca un abanico amplio y hachazo (doble en fase 3).
func _attack_hacha(run: Dictionary) -> void:
	if boss.distance_to_target() > 95.0:
		await boss.dash_towards_target(60.0)
	var swings = 2 if boss.phase >= 3 else 1
	for s in range(swings):
		if _cancelled(run): return
		_aim_at_target(0.0)
		var center = boss.global_position
		PrometeoTelegraph.arc(self, center, aim_angle, 105.0, deg_to_rad(80.0), 0.42, PrometeoTelegraph.COLOR_MELEE)
		await _wait(0.42)
		if _cancelled(run): return
		_slash_flash(boss.global_position, aim_angle, 105.0, deg_to_rad(80.0))
		_hit_target_in_arc(boss.global_position, aim_angle, 105.0, deg_to_rad(80.0), boss.melee_damage)
		boss.play_sfx("slash")
		await _wait(0.22)
	await _wait(0.3)

# Daga: estocadas rápidas en cadena, cada una con su línea de aviso.
func _attack_daga(run: Dictionary) -> void:
	var stabs = 4 if boss.phase >= 3 else 3
	for i in range(stabs):
		if _cancelled(run): return
		_aim_at_target(0.25)
		var reach = boss._clamp_travel(Vector2.from_angle(aim_angle), clampf(boss.distance_to_target() + 30.0, 70.0, 150.0))
		PrometeoTelegraph.line(self, boss.global_position, aim_angle, reach, 0.24, PrometeoTelegraph.COLOR_MELEE, 60.0)
		await _wait(0.24)
		if _cancelled(run): return
		var start = boss.global_position
		await boss.lunge(aim_angle, reach)
		if _cancelled(run): return
		boss.energy_fx.bolt(start, aim_angle, start.distance_to(boss.global_position))
		boss.energy_fx.slash(boss.global_position, aim_angle, 25.0, 0.5)
		_hit_target_near_segment(start, boss.global_position, 30.0, int(boss.melee_damage * 0.8))
		boss.play_sfx("slash")
		await _wait(0.16)
	await _wait(0.3)

# Maza: salto a donde vas a estar, aplastón con onda (y anillo de balas desde la fase 2).
func _attack_maza(run: Dictionary) -> void:
	var landing = boss.safe_landing(boss.predict_target_position(0.45))
	PrometeoTelegraph.circle(self, landing, 105.0, 0.7, PrometeoTelegraph.COLOR_MELEE)
	await boss.leap_to(landing, 0.7)
	if _cancelled(run): return
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
func _attack_espiral(run: Dictionary) -> void:
	await boss.leap_to(boss.safe_landing(boss.arena_center()), 0.6)
	if _cancelled(run): return
	PrometeoTelegraph.circle(self, boss.global_position, 60.0, 0.5, PrometeoTelegraph.COLOR_RANGED)
	boss.play_sfx("roar")
	boss.energy_fx.burst(boss.global_position, 80.0)
	await _wait(0.5)
	var base = randf() * TAU
	var arms = 3
	var elapsed = 0.0
	while elapsed < 4.0:
		if _cancelled(run): return
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
	PrometeoTelegraph.line(self, _muzzle(), aim_angle, length, duration, PrometeoTelegraph.COLOR_RANGED)
	await _wait(duration)

# --- Disparo ---

func _fire_bullet(angle: float, speed: float, tint: Color, p_lifetime: float = 4.0, turn_rate: float = 0.0, homing_time: float = 0.0, origin: Vector2 = Vector2.INF) -> void:
	var bullet = BULLET_SCENE.instantiate()
	bullet.configure(speed, tint, p_lifetime, turn_rate, homing_time)
	bullet.source_name = boss.boss_display_name
	_scene_root().add_child(bullet)
	bullet.global_position = _muzzle() if origin == Vector2.INF else origin
	bullet.setup(Vector2.from_angle(angle), _scaled(boss.bullet_damage), "player")
	boss.energy_fx.shot(bullet.global_position, angle)

func _fire_fan(count: int, spread: float, speed_min: float, speed_max: float, tint: Color) -> void:
	for i in range(count):
		var t = 0.5 if count == 1 else float(i) / float(count - 1)
		var angle = aim_angle - spread * 0.5 + spread * t + randf_range(-0.04, 0.04)
		_fire_bullet(angle, randf_range(speed_min, speed_max), tint, 1.2)

func _muzzle() -> Vector2:
	_update_weapon_pose()
	return _weapon_pivot.to_global(_muzzle_offset)

func _update_weapon_pose() -> void:
	var direction := Vector2.from_angle(aim_angle)
	_weapon_pivot.position = hand_offset + direction * hand_orbit
	_weapon_pivot.rotation = aim_angle
	_weapon_pivot.scale = Vector2(weapon_visual_scale, -weapon_visual_scale if direction.x < 0 else weapon_visual_scale)

func _scaled(value: float) -> int:
	return maxi(1, int(value * damage_mult))

# --- Golpes cuerpo a cuerpo ---

func _hit_target_in_arc(origin: Vector2, angle: float, radius: float, half_angle: float, dmg: float) -> void:
	if not is_instance_valid(boss.target) or not boss.clear_attack_path(origin, boss.target.global_position): return
	var to_target = boss.target.global_position - origin
	if to_target.length() > radius: return
	if absf(wrapf(to_target.angle() - angle, -PI, PI)) > half_angle: return
	boss.deal_damage_to_target(_scaled(dmg))

func _hit_target_near_segment(a: Vector2, b: Vector2, width: float, dmg: float) -> void:
	if not is_instance_valid(boss.target): return
	var closest = Geometry2D.get_closest_point_to_segment(boss.target.global_position, a, b)
	if not boss.clear_attack_path(closest, boss.target.global_position): return
	if closest.distance_to(boss.target.global_position) <= width:
		boss.deal_damage_to_target(_scaled(dmg))

func _hit_target_in_radius(origin: Vector2, radius: float, dmg: float) -> void:
	if not is_instance_valid(boss.target) or not boss.clear_attack_path(origin, boss.target.global_position): return
	if boss.target.global_position.distance_to(origin) <= radius:
		boss.deal_damage_to_target(_scaled(dmg))

# --- Efectos ---

func _slash_flash(center: Vector2, angle: float, radius: float, half_angle: float) -> void:
	boss.energy_fx.slash(center, angle, radius, half_angle)
	PrometeoTelegraph.arc(self, center, angle, radius, half_angle, 0.12, PrometeoTelegraph.COLOR_SLASH)

func _spawn_shockwave(pos: Vector2, radius: float) -> void:
	boss.energy_fx.burst(pos, radius)
	var wave = FuriaShockwave.new()
	wave.max_radius = radius
	wave.set_meta("color_fill", Color(0.5, 0.05, 0.2, 0.35))
	wave.set_meta("color_stroke", Color(1.0, 0.2, 0.4, 0.8))
	_scene_root().add_child(wave)
	wave.global_position = pos

func _play_equip_flourish() -> void:
	var base_scale = _weapon_sprite.scale
	_weapon_sprite.scale = base_scale * 1.15
	_weapon_sprite.modulate = Color(2.5, 0.6, 0.8)
	_equip_tween = _weapon_sprite.create_tween().set_parallel(true)
	_equip_tween.tween_property(_weapon_sprite, "scale", base_scale, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_equip_tween.tween_property(_weapon_sprite, "modulate", Color.WHITE, 0.35)

## Copia sólo el arte de la escena del jugador, sin activar ataques ni colisiones.
## Weapon_mark es el mismo punto de agarre que alinean sus contenedores de armas.
func _set_weapon_visual(id: String) -> void:
	var weapon = (load(WEAPONS[id].scene) as PackedScene).instantiate() as Node2D
	var source: Node2D
	for node_name in ["Weapon_Sprites", "Melee_sprite", "Sprite2D"]:
		source = weapon.get_node_or_null(node_name) as Node2D
		if source: break
	if not source:
		weapon.free()
		return
	if _equip_tween and _equip_tween.is_valid():
		_equip_tween.kill()
	if is_instance_valid(_weapon_sprite):
		_weapon_sprite.free()
	var grip = weapon.find_child("Weapon_mark", true, false) as Node2D
	var grip_position = _scene_transform(grip, weapon).origin if grip else Vector2.ZERO
	var sprite_transform = _scene_transform(source, weapon)
	sprite_transform.origin -= grip_position
	_weapon_sprite = source.duplicate(0) as Node2D
	_weapon_sprite.set_script(null)
	for child in _weapon_sprite.get_children():
		child.free()
	_weapon_sprite.name = "WeaponSprite"
	_weapon_sprite.transform = sprite_transform
	_weapon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_weapon_sprite.show()
	_weapon_pivot.add_child(_weapon_sprite)
	if _weapon_sprite is AnimatedSprite2D:
		_weapon_sprite.stop()
		if _weapon_sprite.sprite_frames.has_animation("idle"):
			_weapon_sprite.play("idle")
	var muzzle = weapon.get_node_or_null("Bullet_mark_right") as Node2D
	_muzzle_offset = _scene_transform(muzzle, weapon).origin - grip_position if muzzle else Vector2(MUZZLE_DISTANCE - WEAPON_ORBIT, 0)
	weapon.free()
	_update_weapon_transform()

func _scene_transform(node: Node2D, root: Node2D) -> Transform2D:
	var result = node.transform
	var parent = node.get_parent()
	while parent != root and parent is Node2D:
		result = parent.transform * result
		parent = parent.get_parent()
	return result

# --- Utilidades ---

func _cancelled(run: Dictionary = {}) -> bool:
	return run.get("cancelled", false) or not is_instance_valid(boss) or not boss.is_inside_tree() or boss.is_attack_cancelled() or not is_instance_valid(boss.target)

func _wait(seconds: float) -> Signal:
	return get_tree().create_timer(maxf(seconds, 0.01), false).timeout

func _scene_root() -> Node:
	return get_tree().current_scene
