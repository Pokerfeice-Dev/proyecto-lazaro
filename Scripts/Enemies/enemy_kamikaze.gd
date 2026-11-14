class_name EnemyKamikaze
extends EnemyFollower
# Kamikaze: corre hacia el jugador y, al tocarlo, se frena y marca un círculo.
# A los 1,2 s explota. Si se lo mata antes (o el jugador sale del círculo), no hace daño.

@export_category("Kamikaze")
@export var kamikaze_speed: float = 210.0
@export var kamikaze_health: int = 24
@export var fuse_time: float = 1.2
@export var trigger_distance: float = 34.0
@export var blast_radius: float = 56.0
@export var blast_damage: int = 22
@export var body_tint: Color = Color(1.0, 1.0, 1.0, 1.0)

var _fuse_left: float = -1.0
var _blink_time: float = 0.0

func _ready() -> void:
	super._ready()
	lunge_enabled = false
	move_speed = kamikaze_speed
	max_health = kamikaze_health
	current_health = max_health
	_default_modulate = body_tint
	if anim_sprite: anim_sprite.modulate = body_tint

func die() -> void:
	_fuse_left = -1.0
	queue_redraw()
	super.die()

# No ataca cuerpo a cuerpo: su único ataque es la explosión.
func _on_attack_timer_timeout() -> void:
	pass

func process_movement(delta: float) -> void:
	if is_dying: return
	if _fuse_left >= 0.0:
		_process_fuse(delta)
		return
	super.process_movement(delta)
	if not has_detected_player or not is_instance_valid(target): return
	if global_position.distance_to(target.global_position) <= trigger_distance:
		_start_fuse()

func _start_fuse() -> void:
	_fuse_left = fuse_time
	_blink_time = 0.0
	velocity = Vector2.ZERO
	play_animation("fuse")
	_play_attack_sound()

func _process_fuse(delta: float) -> void:
	velocity = Vector2.ZERO
	_fuse_left -= delta
	_blink_time += delta
	# Parpadea cada vez más rápido a medida que se acerca la explosión.
	var progress := 1.0 - clampf(_fuse_left / fuse_time, 0.0, 1.0)
	var blink_on := int(_blink_time * lerpf(6.0, 20.0, progress)) % 2 == 0
	if anim_sprite: anim_sprite.modulate = Color(2.6, 0.5, 0.4, 1.0) if blink_on else body_tint
	queue_redraw()
	if _fuse_left <= 0.0: _explode()

func _explode() -> void:
	_fuse_left = -1.0
	if is_instance_valid(target) and global_position.distance_to(target.global_position) <= blast_radius:
		if target.get("is_dashing") != true and target.has_method("take_damage"):
			target.take_damage(blast_damage, "Kamikaze", global_position)
	die()

func _draw() -> void:
	if _fuse_left < 0.0: return
	var progress := 1.0 - clampf(_fuse_left / fuse_time, 0.0, 1.0)
	# Círculo marcado: el relleno crece hasta ocupar toda la zona de explosión.
	draw_circle(Vector2.ZERO, blast_radius, Color(1.0, 0.2, 0.1, 0.12))
	draw_circle(Vector2.ZERO, blast_radius * progress, Color(1.0, 0.25, 0.1, 0.3))
	draw_arc(Vector2.ZERO, blast_radius, 0.0, TAU, 40, Color(1.0, 0.5, 0.2, 0.9), 2.0)

# Muerte animada con el sprite propio (animación "death"); sin ella, desintegración normal.
func _spawn_pixel_death() -> void:
	if not EnemyDeathAnim.play(self): super._spawn_pixel_death()
