extends EnemyBase
class_name EnemyTurret

@export var rotation_speed: float = 3.0
@export var fire_rate: float = 1.5
@export var projectile_scene: PackedScene = preload("res://Scenes/Enemies/enemy_shooter_projectile.tscn")

@onready var sprite_base: Sprite2D = $Sprite_BaseTurret
@onready var sprite_cannon: Sprite2D = $Sprite_CannonTurret
@onready var bullet_mark: Marker2D = $Sprite_CannonTurret/Bullet_Mark

var player_in_shoot_range: bool = false
var shoot_cooldown: float = 0.0

@onready var attack_sound: AudioStreamPlayer2D = $Attack_sound

var _default_base_modulate: Color = Color.WHITE
var _default_cannon_modulate: Color = Color.WHITE
var _turret_flash_tween: Tween = null

func _ready() -> void:
	super._ready()
	if sprite_base:
		_default_base_modulate = sprite_base.modulate
		_default_base_modulate.a = 1.0
	if sprite_cannon:
		_default_cannon_modulate = sprite_cannon.modulate
		_default_cannon_modulate.a = 1.0

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

func _update_shooting() -> void:
	if not player_in_shoot_range: return
	if shoot_cooldown > 0.0: return
	if not target: return
	
	_shoot_projectile()
	shoot_cooldown = fire_rate

func _shoot_projectile() -> void:
	if not projectile_scene: return
	var proj = projectile_scene.instantiate()
	proj.source_name = "Torreta de Seguridad"
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

func _flash_red() -> void:
	if not sprite_base or not sprite_cannon: return
	
	if _turret_flash_tween and _turret_flash_tween.is_valid():
		_turret_flash_tween.kill()
		
	sprite_base.modulate = Color.RED
	sprite_cannon.modulate = Color.RED
	
	_turret_flash_tween = create_tween().set_parallel(true)
	_turret_flash_tween.tween_property(sprite_base, "modulate", _default_base_modulate, 0.2)
	_turret_flash_tween.tween_property(sprite_cannon, "modulate", _default_cannon_modulate, 0.2)
