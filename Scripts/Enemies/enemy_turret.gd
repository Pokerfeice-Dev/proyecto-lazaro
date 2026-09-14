extends EnemyBase
class_name Delivery

@export var rotation_speed: float = 3.0
@export var fire_rate: float = 1.5
@export var projectile_scene: PackedScene = preload("res://Scenes/Enemies/enemy_shooter_projectile.tscn")

@onready var sprite_base: Sprite2D = $Sprite_BaseTurret
@onready var sprite_cannon: Sprite2D = $Sprite_CannonTurret
@onready var bullet_mark: Marker2D = $Sprite_CannonTurret/Bullet_Mark

var player_in_shoot_range: bool = false
var shoot_cooldown: float = 0.0
@export var anticipation_time: float = 0.35
var is_anticipating_shot: bool = false
var _anticipation_tween: Tween = null

@onready var attack_sound: AudioStreamPlayer2D = $Attack_sound

var _default_base_modulate: Color = Color.WHITE
var _default_cannon_modulate: Color = Color.WHITE
var _turret_flash_tween: Tween = null

func _ready() -> void:
	super._ready()
	has_footstep_fx = false
	if sprite_base:
		_default_base_modulate = sprite_base.modulate
		_default_base_modulate.a = 1.0
	if sprite_cannon:
		_default_cannon_modulate = sprite_cannon.modulate
		_default_cannon_modulate.a = 1.0
	if attack_sound: attack_sound.bus = "SFX"

func _exit_tree() -> void:
	_cancel_anticipation()

func die() -> void:
	_cancel_anticipation()
	super.die()

func _play_attack_sound() -> void:
	if attack_sound:
		attack_sound.play()

func apply_knockback(_force: float, _direction: Vector2) -> void:
	pass # Fixed turret does not receive knockback

func process_movement(delta: float) -> void:
	velocity = Vector2.ZERO
	if is_dying: return
	
	_update_cooldown(delta)
	_update_cannon_rotation(delta)
	_update_shooting()

func _update_cooldown(delta: float) -> void:
	if shoot_cooldown > 0.0:
		shoot_cooldown -= delta

func _update_cannon_rotation(delta: float) -> void:
	if not player_in_shoot_range: return
	if not target: return
	
	var target_dir = (target.global_position - global_position).normalized()
	var target_angle = target_dir.angle()
	var angle_diff = wrapf(target_angle - sprite_cannon.rotation, -PI, PI)
	sprite_cannon.rotation += clamp(angle_diff, -rotation_speed * delta, rotation_speed * delta)
	if is_anticipating_shot:
		queue_redraw()

func _update_shooting() -> void:
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
	if not is_anticipating_shot: return
	_draw_aiming_laser()

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
	var proj = projectile_scene.instantiate()
	proj.source_name = "Delivery"
	var spawn_pos = bullet_mark.global_position
	var shoot_dir = Vector2.from_angle(sprite_cannon.global_rotation)
	get_tree().current_scene.add_child(proj)
	proj.global_position = spawn_pos
	proj.setup(shoot_dir, damage, "player")
	_play_attack_sound()

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
	if sprite_base:
		sprite_base.modulate.a = 0.0
	if sprite_cannon:
		sprite_cannon.modulate.a = 0.0

func _fade_in_sprite() -> void:
	var t = create_tween().set_parallel(true)
	if sprite_base:
		t.tween_property(sprite_base, "modulate:a", 1.0, 0.2)
	if sprite_cannon:
		t.tween_property(sprite_cannon, "modulate:a", 1.0, 0.2)
	t.chain().tween_callback(_finish_spawn)

func _hide_sprite() -> void:
	if sprite_base:
		sprite_base.hide()
	if sprite_cannon:
		sprite_cannon.hide()

func _flash_hit() -> void:
	if not sprite_base:
		return
	if not sprite_cannon:
		return
	_cancel_turret_flash_tween()
	sprite_base.modulate = Color(3.0, 3.0, 3.0, 1.0)
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
	_turret_flash_tween.tween_property(sprite_base, "modulate", _default_base_modulate, 0.18)
	_turret_flash_tween.tween_property(sprite_cannon, "modulate", _default_cannon_modulate, 0.18)

func _flash_red() -> void:
	_flash_hit()
