class_name EnemyKiter
extends Carpenter
# Tirador que huye: mantiene la distancia, retrocede si el jugador se acerca
# y dispara tres balas rápidas en tanda; cada una se adelanta a hacia dónde te mueves, así que
# hay que usar el dash para cortar la tanda.

@export_category("Tirador que huye")
@export var kiter_health: int = 24
@export var flee_trigger_distance: float = 150.0
@export var flee_speed_multiplier: float = 1.3
@export var bullet_count: int = 3
@export var bullet_speed: float = 300.0
@export var bullet_gap: float = 0.2
@export var body_tint: Color = Color(1.0, 1.0, 1.0, 1.0)

func _ready() -> void:
	super._ready()
	max_health = kiter_health
	current_health = max_health
	_default_modulate = body_tint
	if anim_sprite: anim_sprite.modulate = body_tint

func process_movement(delta: float) -> void:
	super.process_movement(delta)
	_apply_flee()

# Si el jugador se acerca demasiado, retrocede; si hay pared, bordea hacia un lado.
func _apply_flee() -> void:
	if is_dying or not has_detected_player or not is_instance_valid(target): return
	if is_attacking or is_anticipating_shot: return
	if global_position.distance_to(target.global_position) > flee_trigger_distance: return
	var away := target.global_position.direction_to(global_position)
	for angle in [0.0, PI * 0.5, -PI * 0.5]:
		var candidate: Vector2 = away.rotated(angle)
		if _can_walk_segment(global_position, global_position + candidate * 32.0):
			velocity = candidate * move_speed * flee_speed_multiplier
			update_animation_state()
			return

# Balas en tanda; cada una sale apuntada, adelantándose al movimiento del jugador en ese momento.
func _spawn_projectile(dir: Vector2) -> void:
	_spawn_slow_bullet(dir)
	for i in range(1, bullet_count):
		get_tree().create_timer(bullet_gap * i).timeout.connect(_spawn_delayed_bullet, CONNECT_ONE_SHOT)

func _aim_direction() -> Vector2:
	return lead_direction(global_position, bullet_speed)

# La tanda sale en fila, no en abanico: una sola línea de aviso.
func _aim_line_count() -> int:
	return 1

func _spawn_delayed_bullet() -> void:
	if is_dying or not is_instance_valid(target): return
	_spawn_slow_bullet(_aim_direction())

func _spawn_slow_bullet(dir: Vector2) -> void:
	var proj = projectile_scene.instantiate()
	register_attack(proj)
	proj.source_name = "Tirador"
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	proj.setup(dir, damage, "player")
	proj.speed = bullet_speed

# Muerte animada con el sprite propio (animación "death"); sin ella, desintegración normal.
func _spawn_pixel_death() -> void:
	if not EnemyDeathAnim.play(self): super._spawn_pixel_death()
