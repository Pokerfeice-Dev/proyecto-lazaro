extends EnemyBase
class_name CryptEnemy

enum Kind { GARGOYLE, GHOUL, CENTIPEDE, DEATH_SQUAD, LASER_EYE, DEAD_BEEKEEPER, FLESH_BEE, BELL_KEEPER }
enum Phase { CHASE, ANTICIPATION, ATTACK, RECOVERY, STONE_WARNING, STONE }

@export_category("Identidad de la cripta")
@export var kind: Kind = Kind.GARGOYLE
@export var codex_id := "crypt_gargoyle"
@export var display_name := "Gárgola"
@export_category("Ritmo de combate")
@export var attack_range := 58.0
@export var anticipation_time := 0.55
@export var attack_duration := 0.35
@export var recovery_time := 0.95
@export var projectile_scene: PackedScene = preload("res://Scenes/Projectiles/crypt_projectile.tscn")
@export var projectile_speed := 300.0
@export_category("Gárgola")
@export var stone_duration := 2.0
@export var stone_cooldown := 5.0
@export var stone_warning_time := 0.45
@export_category("Ghoul")
@export var rear_speed_multiplier := 1.75
@export_range(-1.0, 1.0) var rear_dot_threshold := -0.35
@export_category("Spray tóxico")
@export_range(10.0, 160.0) var spray_angle_degrees := 56.0
@export var poison_scene: PackedScene = preload("res://Scenes/Effects/crypt_poison.tscn")
@export_category("Ojo láser")
@export var laser_lock_time := 0.55
@export var laser_half_width := 10.0
@export_category("Invocación")
@export var summon_scene: PackedScene
@export var max_summons := 2
@export var summons_per_attack := 2
## Segundos sin invocar después de que muere una de sus abejas.
@export var summon_cooldown := 15.0
@export_category("Campanero")
@export var echo_scene: PackedScene = preload("res://Scenes/Effects/crypt_echo.tscn")
@export var echo_count := 3
@export_category("Arte")
## Activar si el sprite original mira hacia la izquierda.
@export var art_faces_left := false
## Girar el sprite hacia donde va en vez de espejarlo (ciempiés).
@export var art_rotates := false
## Hacia dónde mira el dibujo original, en grados (0 = derecha, 90 = abajo).
@export var art_forward_degrees := 0.0
## Flotación vertical en píxeles (abejas y ojos).
@export var hover_amplitude := 0.0
## Qué tan rápido gira al perseguir; valores bajos dan curvas más amplias.
@export var turn_rate := 9.0

const TOXIC_TINT := Color(0.62, 1.0, 0.2)
const BELL_TINT := Color(0.5, 0.92, 1.0)
const HIVE_TINT := Color(1.0, 0.55, 0.42)
const GHOST_TINT := Color(1.0, 0.45, 0.75, 0.55)
const HEALTH_BAR_GAP := 6.0

var phase: Phase = Phase.CHASE
var locked_direction := Vector2.RIGHT
var _shield_cooldown := 2.0
var _shots_remaining := 0
var _attack_hit := false
var _spray_tick := 0.0
var _summons: Array[Node] = []
var _summon_cooldown_left := 0.0
var _echoes: Array[Node] = []
var is_summoned := false
var _move_dir := Vector2.ZERO
var _visual_time := 0.0
var _rushing := false

@onready var art_sprite: AnimatedSprite2D = _find_art_sprite()
@onready var art := CryptEnemyArt.new(self, art_sprite)
@onready var telegraph: CryptTelegraph = $Telegraph
@onready var gas: CPUParticles2D = get_node_or_null("GasParticles") as CPUParticles2D

func _ready() -> void:
	super._ready()
	has_footstep_fx = false
	$PhaseTimer.timeout.connect(_next_phase)
	$BurstTimer.timeout.connect(_fire_burst_shot)
	$HealthBar.max_value = max_health
	$HealthBar.value = current_health
	if kind == Kind.DEAD_BEEKEEPER: add_to_group("crypt_summoner")
	if art_sprite:
		$Sprite2D.hide()
		art.play([&"idle"])
		_place_health_bar()
	_visual_time = randf() * TAU
	_configure_telegraph()

# Las barras y el arte provisional son nodos de la escena, no se crean al ejecutar.
func _setup_health_bar() -> void:
	pass

# La barra queda justo encima del sprite, como en los enemigos del área 1.
func _place_health_bar() -> void:
	var texture := art_sprite.sprite_frames.get_frame_texture(art_sprite.animation, 0)
	if texture == null: return
	var half_height := texture.get_size().y * absf(art_sprite.scale.y) * 0.5
	if art_rotates: half_height = texture.get_size().length() * absf(art_sprite.scale.y) * 0.4
	var top := art_sprite.position.y - half_height - HEALTH_BAR_GAP
	$HealthBar.offset_top = top - 4.0
	$HealthBar.offset_bottom = top

func _process(delta: float) -> void:
	_visual_time += delta
	if phase == Phase.ANTICIPATION:
		telegraph.direction = locked_direction
		telegraph.charge(_phase_progress())
	var shaking := phase == Phase.ANTICIPATION or phase == Phase.STONE_WARNING
	art.update(delta, _visual_time, _phase_progress() if shaking else 0.0)
	art.afterimages(delta, _rushing and phase == Phase.CHASE and velocity.length_squared() > 100.0, GHOST_TINT)

func process_movement(delta: float) -> void:
	velocity = Vector2.ZERO
	if is_dying or is_spawning or not is_instance_valid(target): return
	_shield_cooldown = maxf(0.0, _shield_cooldown - delta)
	_summon_cooldown_left = maxf(0.0, _summon_cooldown_left - delta)
	if phase == Phase.ANTICIPATION and kind == Kind.LASER_EYE:
		if $PhaseTimer.time_left > laser_lock_time:
			locked_direction = global_position.direction_to(target.global_position)
		_update_aim()
	elif phase == Phase.ATTACK:
		if kind == Kind.LASER_EYE: _damage_laser()
		elif kind == Kind.CENTIPEDE:
			_spray_tick -= delta
			if _spray_tick <= 0.0:
				_spray_tick = 0.3
				_apply_poison_in_cone()
	if phase != Phase.CHASE: return
	if not has_detected_player:
		art.walk(Vector2.ZERO)
		return
	var distance = global_position.distance_to(target.global_position)
	if distance <= attack_range and _clear_path_to(target.global_position):
		if kind != Kind.DEAD_BEEKEEPER or _can_summon():
			_begin_attack()
		return
	if kind == Kind.LASER_EYE:
		art.face(global_position.direction_to(target.global_position))
		art.walk(Vector2.ZERO)
		return
	var speed_multiplier = rear_speed_multiplier if kind == Kind.GHOUL and player_has_back_turned() else 1.0
	_steer(get_nav_direction_to_target(), delta)
	velocity = _move_dir * move_speed * speed_multiplier
	art.walk(velocity)
	_rushing = speed_multiplier > 1.0

# Gira de forma gradual hacia la dirección deseada, sin perder velocidad.
func _steer(desired: Vector2, delta: float) -> void:
	if desired == Vector2.ZERO:
		_move_dir = Vector2.ZERO
		return
	_move_dir = _move_dir.lerp(desired, minf(1.0, turn_rate * delta))
	_move_dir = _move_dir.normalized() if _move_dir.length_squared() > 0.0001 else desired

func player_has_back_turned() -> bool:
	if not is_instance_valid(target): return false
	var aim = target.get_aim_position() if target.has_method("get_aim_position") else target.get_global_mouse_position()
	var facing = (aim - target.global_position).normalized()
	if "last_dir" in target:
		var directions = {"right": Vector2.RIGHT, "left": Vector2.LEFT, "up": Vector2.UP, "down": Vector2.DOWN, "up_right": Vector2(1, -1).normalized(), "up_left": Vector2(-1, -1).normalized(), "down_right": Vector2(1, 1).normalized(), "down_left": Vector2(-1, 1).normalized()}
		facing = directions.get(target.last_dir, facing)
	var to_enemy = target.global_position.direction_to(global_position)
	return facing.dot(to_enemy) < rear_dot_threshold

func _begin_attack() -> void:
	locked_direction = global_position.direction_to(target.global_position)
	_attack_hit = false
	_rushing = false
	_update_aim()
	telegraph.summon_points = PackedVector2Array([_summon_offset(0), _summon_offset(1)])
	_enter_phase(Phase.ANTICIPATION, anticipation_time)

func _enter_phase(next: Phase, duration: float) -> void:
	phase = next
	velocity = Vector2.ZERO
	$StoneShield.visible = (phase == Phase.STONE or phase == Phase.STONE_WARNING) and art_sprite == null
	$StoneShield.modulate.a = 1.0 if phase == Phase.STONE else 0.4
	if phase == Phase.ANTICIPATION or phase == Phase.STONE_WARNING:
		$AnimationPlayer.play("anticipation")
	elif phase == Phase.ATTACK:
		$AnimationPlayer.play("attack")
	else:
		$AnimationPlayer.play("RESET")
	_update_phase_fx(duration)
	_update_phase_art()
	$PhaseTimer.start(maxf(duration, 0.01))

func _update_phase_fx(duration: float) -> void:
	if gas: gas.emitting = phase == Phase.ATTACK
	match phase:
		Phase.ANTICIPATION:
			telegraph.direction = locked_direction
			telegraph.charge(0.0)
		Phase.ATTACK:
			telegraph.direction = locked_direction
			if kind in [Kind.GARGOYLE, Kind.GHOUL, Kind.CENTIPEDE, Kind.LASER_EYE]:
				telegraph.strike(duration)
			else:
				telegraph.stop()
			if kind in [Kind.GARGOYLE, Kind.GHOUL]: art.recoil = locked_direction * 7.0
			if gas: gas.rotation = locked_direction.angle()
		_:
			telegraph.stop()

func _update_phase_art() -> void:
	if not art_sprite: return
	art.face(locked_direction)
	match phase:
		Phase.ANTICIPATION: art.play([&"attack_windup", &"attack"], true)
		Phase.ATTACK: art.play([&"attack_cone", &"attack"], true)
		Phase.STONE_WARNING: art.play([&"petrify"], true)
		Phase.STONE: art.play([&"stone_shield"])
		Phase.RECOVERY: art.play([&"idle"])

func _find_art_sprite() -> AnimatedSprite2D:
	var node = get_node_or_null("ArtSprite")
	if node == null: node = get_node_or_null("GargoyleSprite")
	return node as AnimatedSprite2D

func _phase_progress() -> float:
	var total: float = $PhaseTimer.wait_time
	if total <= 0.0: return 1.0
	return clampf(1.0 - $PhaseTimer.time_left / total, 0.0, 1.0)

func _next_phase() -> void:
	if is_dying: return
	match phase:
		Phase.ANTICIPATION:
			_enter_phase(Phase.ATTACK, attack_duration)
			_perform_attack()
		Phase.ATTACK:
			$BurstTimer.stop()
			_enter_phase(Phase.RECOVERY, recovery_time)
		Phase.RECOVERY:
			if kind == Kind.GARGOYLE and _shield_cooldown <= 0.0:
				_enter_phase(Phase.STONE_WARNING, stone_warning_time)
			else:
				phase = Phase.CHASE
		Phase.STONE_WARNING:
			knockback_velocity = Vector2.ZERO
			_enter_phase(Phase.STONE, stone_duration)
		Phase.STONE:
			_shield_cooldown = stone_cooldown
			_enter_phase(Phase.RECOVERY, recovery_time)

func _perform_attack() -> void:
	$AttackSound.play()
	match kind:
		Kind.GARGOYLE, Kind.GHOUL:
			if _target_in_cone(attack_range + 12.0, 100.0):
				target.take_damage(damage, display_name, global_position)
		Kind.CENTIPEDE:
			_spray_tick = 0.0
		Kind.DEATH_SQUAD:
			_shots_remaining = 3
			_fire_burst_shot()
		Kind.BELL_KEEPER:
			_shots_remaining = mini(echo_count, 3)
			_fire_burst_shot()
		Kind.FLESH_BEE:
			_spawn_projectile()
		Kind.DEAD_BEEKEEPER:
			for index in mini(summons_per_attack, max_summons - _live_summons()):
				_spawn_bee(index)

func _fire_burst_shot() -> void:
	if is_dying or phase != Phase.ATTACK or _shots_remaining <= 0: return
	if kind == Kind.BELL_KEEPER:
		_place_echo()
	else:
		_spawn_projectile()
	_shots_remaining -= 1
	if _shots_remaining > 0: $BurstTimer.start()

func _place_echo() -> void:
	if not is_instance_valid(target) or not _clear_path_to(target.global_position): return
	_echoes = _echoes.filter(func(mark): return is_instance_valid(mark))
	if _echoes.size() >= 3: return
	var echo = echo_scene.instantiate()
	echo.damage = damage
	get_parent().add_child(echo)
	echo.global_position = target.global_position
	_echoes.append(echo)
	$AttackSound.play()
	telegraph.ring_at(Vector2.ZERO, 54.0)
	art.recoil = Vector2(0, -3)

func _spawn_projectile() -> void:
	var projectile = projectile_scene.instantiate()
	projectile.direction = locked_direction
	projectile.damage = damage
	projectile.speed = projectile_speed
	projectile.source_name = display_name
	get_parent().add_child(projectile)
	projectile.global_position = global_position + locked_direction * 20.0
	telegraph.direction = locked_direction
	telegraph.flash_at(locked_direction * 18.0, 7.0 if kind == Kind.FLESH_BEE else 9.0)
	art.recoil = -locked_direction * 4.0

func _target_in_cone(reach: float, angle_degrees: float) -> bool:
	if not is_instance_valid(target): return false
	var offset = target.global_position - global_position
	return offset.length() <= reach and locked_direction.dot(offset.normalized()) >= cos(deg_to_rad(angle_degrees * 0.5)) and _clear_path_to(target.global_position)

func _apply_poison_in_cone() -> void:
	if not _target_in_cone(attack_range, spray_angle_degrees): return
	if target.get("is_dashing") == true or target.get("is_invulnerable") == true: return
	var poison = target.get_node_or_null("CryptPoison")
	if poison == null:
		poison = poison_scene.instantiate()
		target.add_child(poison)
	poison.refresh(global_position)

func _damage_laser() -> void:
	_update_aim()
	if _attack_hit or not is_instance_valid(target): return
	var end = _beam_end()
	var closest = Geometry2D.get_closest_point_to_segment(target.global_position, global_position, end)
	if closest.distance_to(target.global_position) <= laser_half_width + 8.0 and _clear_path_to(target.global_position):
		target.take_damage(damage, display_name, global_position)
		_attack_hit = true

func _beam_end() -> Vector2:
	var end = global_position + locked_direction * attack_range
	var query = PhysicsRayQueryParameters2D.create(global_position, end, 5, [get_rid(), target.get_rid()])
	var hit = get_world_2d().direct_space_state.intersect_ray(query)
	return hit.position if not hit.is_empty() else end

func _clear_path_to(point: Vector2) -> bool:
	var query = PhysicsRayQueryParameters2D.create(global_position, point, 5, [get_rid(), target.get_rid()])
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _update_aim() -> void:
	telegraph.direction = locked_direction
	if kind == Kind.LASER_EYE:
		telegraph.beam_length = global_position.distance_to(_beam_end())

# Cada tipo de enemigo usa un estilo de aviso distinto.
func _configure_telegraph() -> void:
	var styles := {
		Kind.GARGOYLE: CryptTelegraph.Style.CONE, Kind.GHOUL: CryptTelegraph.Style.CONE,
		Kind.CENTIPEDE: CryptTelegraph.Style.CONE, Kind.LASER_EYE: CryptTelegraph.Style.BEAM,
		Kind.DEATH_SQUAD: CryptTelegraph.Style.AIM, Kind.FLESH_BEE: CryptTelegraph.Style.AIM,
		Kind.BELL_KEEPER: CryptTelegraph.Style.RINGS, Kind.DEAD_BEEKEEPER: CryptTelegraph.Style.SUMMON,
	}
	var tints := {Kind.CENTIPEDE: TOXIC_TINT, Kind.BELL_KEEPER: BELL_TINT, Kind.DEAD_BEEKEEPER: HIVE_TINT}
	telegraph.setup(styles[kind], attack_range, tints.get(kind, CryptTelegraph.DANGER))
	telegraph.angle_degrees = spray_angle_degrees if kind == Kind.CENTIPEDE else 100.0
	telegraph.sustained = kind == Kind.CENTIPEDE
	telegraph.pips = 3 if kind == Kind.DEATH_SQUAD else 1
	telegraph.beam_half_width = laser_half_width
	telegraph.beam_length = attack_range
	telegraph.lock_ratio = clampf(1.0 - laser_lock_time / maxf(anticipation_time, 0.01), 0.0, 1.0)
	telegraph.summon_points = PackedVector2Array([_summon_offset(0), _summon_offset(1)])
	if gas: gas.spread = spray_angle_degrees * 0.5

func _summon_offset(index: int) -> Vector2:
	return Vector2(44.0, 0).rotated(locked_direction.angle() + (PI * 0.5 if index % 2 == 0 else -PI * 0.5))

# La apicultora solo invoca si le falta alguna abeja y ya pasó la espera.
func _can_summon() -> bool:
	return _summon_cooldown_left <= 0.0 and _live_summons() < max_summons

func _on_bee_died(_bee) -> void:
	_summon_cooldown_left = summon_cooldown

func _live_summons() -> int:
	_summons = _summons.filter(func(bee): return is_instance_valid(bee) and not bee.is_dying)
	return _summons.size()

func _spawn_bee(index: int) -> void:
	if summon_scene == null: return
	var offset = _summon_offset(index)
	var position_to_use = global_position + offset
	telegraph.ring_at(offset, 22.0)
	if not _clear_path_to(position_to_use): return
	var bee = summon_scene.instantiate()
	bee.is_summoned = true
	get_parent().add_child(bee)
	bee.global_position = position_to_use
	bee.alert_to_player()
	bee.flesh_drop_chance = 0.0
	bee.item_drop_chance = 0.0
	_summons.append(bee)
	bee.enemy_died.connect(_on_bee_died)
	bee.spawn_appear()

func take_damage(amount: int, is_crit: bool = false) -> void:
	if is_dying or phase == Phase.STONE: return
	super.take_damage(amount, is_crit)
	if not is_dying and (phase == Phase.CHASE or phase == Phase.RECOVERY): art.hurt()
	if not is_dying and kind == Kind.GARGOYLE and phase == Phase.CHASE and _shield_cooldown <= 0.0:
		_enter_phase(Phase.STONE_WARNING, stone_warning_time)

func apply_knockback(force: float, direction: Vector2) -> void:
	if phase == Phase.STONE: return
	super.apply_knockback(force, direction)

func _unlock_bestiary_entry() -> void:
	GameData.unlock_codex_entry("enemies", codex_id)

func _attempt_drops() -> void:
	if is_summoned: return
	super._attempt_drops()

func _get_sprite() -> Node2D:
	var node := _find_art_sprite()
	return node if node else get_node_or_null("Sprite2D") as Node2D

func spawn_appear() -> void:
	super.spawn_appear()
	art.play([&"summon"], true)

# Queda el cadáver en la sala; el estallido azul (Death_fx) es el mismo del área 1.
func _hide_sprite() -> void:
	_cancel_active_flash_tween()
	art.leave_corpse()
	$Sprite2D.hide()
	for node in get_children():
		if node.has_method("crypt_death"): node.crypt_death()

func die() -> void:
	if is_dying: return
	$PhaseTimer.stop()
	$BurstTimer.stop()
	telegraph.clear()
	if gas: gas.emitting = false
	$StoneShield.hide()
	_rushing = false
	for bee in _summons:
		if is_instance_valid(bee): bee.queue_free()
	_summons.clear()
	for echo in _echoes:
		if is_instance_valid(echo): echo.queue_free()
	_echoes.clear()
	super.die()
