class_name EnemyWanderingArm
extends EnemyFollower
# Brazo errante (Área 3): repta rápido, salta hacia el jugador y se aferra 1 s
# haciendo daño. Un dash lo sacude y lo deja aturdido. Sprite provisional (perro).

@export_category("Brazo errante")
@export var arm_speed: float = 150.0
@export var arm_health: int = 28
@export var cling_time: float = 1.0
@export var cling_tick_damage: int = 3
@export var cling_tick_interval: float = 0.35
## Aturdimiento al fallar el salto o al ser sacudido con un dash.
@export var shake_stun: float = 0.9
@export var body_tint: Color = Color(1.0, 1.0, 1.0, 1.0)

var _cling_left: float = 0.0
var _cling_tick_left: float = 0.0
var _cling_offset: Vector2 = Vector2(0, -6)

func _ready() -> void:
	super._ready()
	move_speed = arm_speed
	max_health = arm_health
	current_health = max_health
	lunge_enabled = true
	lunge_min_distance = 50.0
	lunge_max_distance = 200.0
	lunge_windup = 0.3
	lunge_speed = 380.0
	lunge_duration = 0.35
	lunge_stun = shake_stun
	lunge_cooldown = 1.8
	_default_modulate = body_tint
	if anim_sprite: anim_sprite.modulate = body_tint

func die() -> void:
	_cling_left = 0.0
	super.die()

# No hace ataque cuerpo a cuerpo normal: solo salta y se aferra.
func _on_attack_timer_timeout() -> void:
	pass

func _process_lunge(delta: float) -> bool:
	if _cling_left > 0.0:
		_process_cling(delta)
		return true
	return super._process_lunge(delta)

# Si el salto conecta, en vez de seguir de largo se aferra al jugador.
func _apply_lunge_damage() -> void:
	if _lunge_hit or is_dying: return
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			_lunge_hit = true
			body.take_damage(damage, "Brazo errante", global_position)
			_start_cling()
			return

func _start_cling() -> void:
	_lunge_phase = LungePhase.NONE
	_cling_left = cling_time
	_cling_tick_left = cling_tick_interval
	velocity = Vector2.ZERO
	_restore_sprite_modulate()
	play_animation("cling")

func _process_cling(delta: float) -> void:
	if is_dying or not is_instance_valid(target):
		_end_cling(false)
		return
	# El dash lo sacude.
	if target.get("is_dashing") == true:
		_end_cling(true)
		return
	velocity = Vector2.ZERO
	global_position = target.global_position + _cling_offset
	_cling_left -= delta
	_cling_tick_left -= delta
	if _cling_tick_left <= 0.0:
		_cling_tick_left = cling_tick_interval
		if target.has_method("take_damage"):
			target.take_damage(cling_tick_damage, "Brazo errante", global_position)
	if _cling_left <= 0.0:
		_end_cling(false)

func _end_cling(shaken: bool) -> void:
	_cling_left = 0.0
	if shaken:
		if is_instance_valid(target):
			apply_knockback(260.0, target.global_position.direction_to(global_position))
		_start_lunge_stun()
	else:
		_end_lunge()

# Muerte animada con el sprite propio (animación "death"); sin ella, desintegración normal.
func _spawn_pixel_death() -> void:
	if not EnemyDeathAnim.play(self): super._spawn_pixel_death()
