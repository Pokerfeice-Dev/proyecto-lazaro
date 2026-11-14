extends EnemyBase
class_name Delivery

@export var rotation_speed: float = 3.0
@export var fire_rate: float = 2.2
@export var projectile_scene: PackedScene = preload("res://Scenes/Enemies/enemy_shooter_projectile.tscn")

@onready var sprite_cannon: Sprite2D = $Sprite_CannonTurret
@onready var bullet_mark: Marker2D = $Sprite_CannonTurret/Bullet_Mark

var player_in_shoot_range: bool = false
var shoot_cooldown: float = 0.0
@export var anticipation_time: float = 0.35
@export_category("Ráfaga")
## Balas por disparo (solo en modo normal). Salen en fila, apuntadas adelantándose al jugador.
@export var burst_count: int = 3
@export var burst_gap: float = 0.14
@export var bullet_speed: float = 520.0

# Variantes de la torreta: bala normal, bala teledirigida lenta o láser que barre.
enum FireMode {
	NORMAL,
	HOMING,
	LASER
}

@export var fire_mode: FireMode = FireMode.NORMAL
@export_category("Teledirigida")
@export var homing_speed: float = 220.0
@export var homing_turn_rate: float = 2.2
@export var homing_duration: float = 2.0
@export_category("Láser")
@export var laser_duration: float = 1.4
@export var laser_length: float = 250.0
@export var laser_half_width: float = 9.0
@export var laser_sweep_speed: float = 1.1
@export var laser_tick_time: float = 0.4

var _laser_time_left: float = 0.0
var _laser_tick_left: float = 0.0
var _laser_sweep_sign: float = 1.0
var is_anticipating_shot: bool = false
var _anticipation_tween: Tween = null

@onready var attack_sound: AudioStreamPlayer2D = $Attack_sound

var _default_cannon_modulate: Color = Color.WHITE
var _turret_flash_tween: Tween = null

func _ready() -> void:
	super._ready()
	has_footstep_fx = false
	for enemy in get_tree().get_nodes_in_group("enemy"):
		_ignore_enemy_collision(enemy)
	get_tree().node_added.connect(_on_body_added)
	if sprite_cannon:
		_default_cannon_modulate = sprite_cannon.modulate
		_default_cannon_modulate.a = 1.0
	if attack_sound: attack_sound.bus = "SFX"

func _exit_tree() -> void:
	_cancel_anticipation()

func die() -> void:
	_cancel_anticipation()
	_laser_time_left = 0.0
	super.die()

func _play_attack_sound() -> void:
	if attack_sound:
		attack_sound.play()

func apply_knockback(_force: float, _direction: Vector2) -> void:
	pass # Fixed turret does not receive knockback

# Torreta anclada: ni los empujones de otros enemigos la mueven. Se fija donde
# está en su primer cuadro de física y vuelve ahí después de cada move_and_slide.
var _anchor := Vector2.INF

func _physics_process(delta: float) -> void:
	super(delta)
	if _anchor == Vector2.INF:
		_anchor = global_position
	elif global_position != _anchor:
		global_position = _anchor

func process_movement(delta: float) -> void:
	velocity = Vector2.ZERO
	if is_dying: return
	
	_update_cooldown(delta)
	_update_laser(delta)
	_update_cannon_rotation(delta)
	_update_shooting()

func _update_cooldown(delta: float) -> void:
	if shoot_cooldown > 0.0:
		shoot_cooldown -= delta

func _update_cannon_rotation(delta: float) -> void:
	if _laser_time_left > 0.0: return
	if not player_in_shoot_range: return
	if not target: return
	
	var target_dir = (target.global_position - global_position).normalized()
	if fire_mode == FireMode.NORMAL:
		target_dir = lead_direction(global_position, bullet_speed)
	var target_angle = target_dir.angle()
	var angle_diff = wrapf(target_angle - sprite_cannon.rotation, -PI, PI)
	sprite_cannon.rotation += clamp(angle_diff, -rotation_speed * delta, rotation_speed * delta)
	if is_anticipating_shot:
		queue_redraw()

func _update_shooting() -> void:
	if _laser_time_left > 0.0: return
	if not player_in_shoot_range: return
	if shoot_cooldown > 0.0: return
	if not target: return
	if is_anticipating_shot: return
	_start_shoot_anticipation()

func _start_shoot_anticipation() -> void:
	if is_dying: return
	is_anticipating_shot = true
	_play_anticipation_visuals()
	queue_redraw()
	get_tree().create_timer(anticipation_time).timeout.connect(_on_anticipation_finished, CONNECT_ONE_SHOT)

func _play_anticipation_visuals() -> void:
	if not sprite_cannon: return
	_cancel_anticipation_tween()
	_anticipation_tween = create_tween()
	_anticipation_tween.tween_property(sprite_cannon, "modulate", Color(2.4, 0.35, 0.35, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_anticipation_finished() -> void:
	if is_dying: return
	if not is_anticipating_shot: return
	is_anticipating_shot = false
	_restore_cannon_modulate()
	queue_redraw()
	if not player_in_shoot_range or not target: return
	if fire_mode == FireMode.LASER:
		_start_laser()
		return
	_shoot_projectile()
	shoot_cooldown = fire_rate

func _restore_cannon_modulate() -> void:
	_cancel_anticipation_tween()
	if not sprite_cannon: return
	sprite_cannon.modulate = _default_cannon_modulate

func _cancel_anticipation_tween() -> void:
	if not _anticipation_tween: return
	if not _anticipation_tween.is_valid(): return
	_anticipation_tween.kill()
	_anticipation_tween = null

func _cancel_anticipation() -> void:
	if not is_anticipating_shot: return
	is_anticipating_shot = false
	_restore_cannon_modulate()
	queue_redraw()

func _draw() -> void:
	if _laser_time_left > 0.0:
		_draw_laser_beam()
		return
	if not is_anticipating_shot: return
	_draw_aiming_laser()

# --- Láser que barre ---

func _start_laser() -> void:
	_laser_time_left = laser_duration
	_laser_tick_left = 0.0
	_laser_sweep_sign = 1.0 if randf() < 0.5 else -1.0
	_play_attack_sound()
	queue_redraw()

func _update_laser(delta: float) -> void:
	if _laser_time_left <= 0.0: return
	_laser_time_left -= delta
	sprite_cannon.rotation += _laser_sweep_sign * laser_sweep_speed * delta
	_laser_tick_left = maxf(0.0, _laser_tick_left - delta)
	_damage_with_laser()
	queue_redraw()
	if _laser_time_left <= 0.0:
		shoot_cooldown = fire_rate * 2.0

# Devuelve [inicio, fin] del rayo; se corta contra las paredes.
func _laser_segment() -> Array:
	var start_pos = bullet_mark.global_position
	var end_pos = start_pos + Vector2.from_angle(sprite_cannon.global_rotation) * laser_length
	var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
	query.collision_mask = EnemyNavigation.OBSTACLE_MASK
	var hit = get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty(): end_pos = hit.position
	return [start_pos, end_pos]

func _damage_with_laser() -> void:
	if _laser_tick_left > 0.0 or not is_instance_valid(target): return
	var segment = _laser_segment()
	var closest = Geometry2D.get_closest_point_to_segment(target.global_position, segment[0], segment[1])
	if closest.distance_to(target.global_position) > laser_half_width: return
	if not target.has_method("take_damage"): return
	target.take_damage(damage, "Delivery", global_position)
	_laser_tick_left = laser_tick_time

func _draw_laser_beam() -> void:
	if not bullet_mark or not sprite_cannon: return
	var segment = _laser_segment()
	var start_pos = to_local(segment[0])
	var end_pos = to_local(segment[1])
	draw_line(start_pos, end_pos, Color(1.0, 0.25, 0.2, 0.35), laser_half_width * 2.0)
	draw_line(start_pos, end_pos, Color(1.0, 0.85, 0.5, 0.95), 2.5)

func _draw_aiming_laser() -> void:
	if not bullet_mark or not sprite_cannon: return
	var start_pos = to_local(bullet_mark.global_position)
	var shoot_dir = Vector2.from_angle(sprite_cannon.global_rotation)
	var end_pos = start_pos + shoot_dir * 180.0
	var laser_color = Color(1.0, 0.2, 0.2, 0.6)
	var glow_color = Color(1.0, 0.6, 0.2, 0.8)
	draw_line(start_pos, end_pos, laser_color, 1.5)
	draw_circle(start_pos, 2.5, glow_color)

func _shoot_projectile() -> void:
	if not projectile_scene: return
	_fire_bullet()
	if fire_mode == FireMode.NORMAL:
		for i in range(1, burst_count):
			get_tree().create_timer(burst_gap * i).timeout.connect(_fire_burst_bullet, CONNECT_ONE_SHOT)
	_play_attack_sound()

# En ráfaga cada bala pega menos, para que la tanda completa pese lo mismo que antes un solo disparo y medio.
func _bullet_damage_ratio() -> float:
	if fire_mode == FireMode.NORMAL and burst_count > 1: return 0.55
	return 1.0

func _fire_burst_bullet() -> void:
	if is_dying: return
	_fire_bullet()

func _fire_bullet() -> void:
	var proj = projectile_scene.instantiate()
	register_attack(proj)
	proj.source_name = "Delivery"
	var spawn_pos = bullet_mark.global_position
	var shoot_dir = Vector2.from_angle(sprite_cannon.global_rotation)
	get_tree().current_scene.add_child(proj)
	proj.global_position = spawn_pos
	proj.setup(shoot_dir, damage * _bullet_damage_ratio(), "player")
	if fire_mode == FireMode.HOMING:
		proj.speed = homing_speed
		proj.homing_turn_rate = homing_turn_rate
		proj.homing_time_left = homing_duration
	else:
		proj.speed = bullet_speed

# --- Señales conectadas desde el Inspector/Escena ---

func _on_shoot_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_shoot_range = true

func _on_shoot_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_shoot_range = false
		_cancel_anticipation()

# --- Sobrescribir funciones de efectos visuales de Sprite ---

func _hide_sprite_alpha() -> void:
	if sprite_cannon:
		sprite_cannon.modulate.a = 0.0

func _fade_in_sprite() -> void:
	if is_dying: return
	var t = create_tween().set_parallel(true)
	if sprite_cannon:
		t.tween_property(sprite_cannon, "modulate:a", 1.0, 0.2)
	t.chain().tween_callback(_finish_spawn)

func _hide_sprite() -> void:
	if sprite_cannon:
		sprite_cannon.hide()

func _flash_hit() -> void:
	if not sprite_cannon:
		return
	_cancel_turret_flash_tween()
	sprite_cannon.modulate = Color(3.0, 3.0, 3.0, 1.0)
	_start_turret_flash_tween()

func _cancel_turret_flash_tween() -> void:
	if not _turret_flash_tween:
		return
	if not _turret_flash_tween.is_valid():
		return
	_turret_flash_tween.kill()

func _start_turret_flash_tween() -> void:
	_turret_flash_tween = create_tween().set_parallel(true)
	_turret_flash_tween.tween_property(sprite_cannon, "modulate", _default_cannon_modulate, 0.18)

func _flash_red() -> void:
	_flash_hit()

# Preserve the damage body for bullets/melee, but let enemies pass through it.
func _on_body_added(node: Node) -> void:
	if node is PhysicsBody2D:
		_ignore_enemy_collision.call_deferred(node)

func _ignore_enemy_collision(node: Node) -> void:
	if not is_instance_valid(node) or node == self: return
	if node is PhysicsBody2D and node.is_in_group("enemy"):
		add_collision_exception_with(node)
		node.add_collision_exception_with(self)
