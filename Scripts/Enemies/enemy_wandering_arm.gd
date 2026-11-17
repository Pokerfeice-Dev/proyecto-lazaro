class_name EnemyWanderingArm
extends EnemyFollower
# Brazo errante (Zona 3): caza al jugador reptando en zigzag y, cuando el salto está listo, lo
# rodea esperando el momento. No tiene golpe cuerpo a cuerpo: su ataque es el SALTO.
#  - Aviso: se enrolla 0,3 s y una línea roja marca hasta dónde llega (se esquiva de lado).
#  - Si te alcanza se enrosca en ti: daño inicial, luego pellizcos cada 0,35 s y te ATURDE
#    (no puedes caminar ni hacer dash; sí apuntar y disparar). Se ve enroscado en tu cuerpo
#    (GripOverlay). Tiene poca vida: mátalo para soltarte antes.
#  - Si falla el salto queda aturdido: ventana para castigarlo.

@export_category("Brazo errante")
@export var arm_speed: float = 150.0
@export var arm_health: int = 28
@export var leap_damage: int = 9
## Cuánto te tiene enroscado y aturdido.
@export var cling_time: float = 1.3
@export var cling_tick_damage: int = 3
@export var cling_tick_interval: float = 0.35
## Aturdimiento del propio brazo cuando falla el salto.
@export var shake_stun: float = 0.8
## Distancia a la que "agarra" en pleno salto (además del área de ataque).
@export var grab_radius: float = 34.0
@export_group("Movimiento")
@export var weave_amount: float = 0.55
@export var weave_frequency: float = 5.5
@export var orbit_distance: float = 110.0
@export var body_tint: Color = Color(1.0, 1.0, 1.0, 1.0)

var _cling_left: float = 0.0
var _cling_tick_left: float = 0.0
var _cling_offset: Vector2 = Vector2(8, -6)
const GRIP_SHEET := "res://Art/Enemies/Redesign/wandering_arm_grip.png"

var _grip_key: String = ""
var _gripped_target: Node = null
var _grip_overlay: GripOverlay = null
var _weave_time: float = 0.0
var _orbit_sign: float = 1.0
var _orbit_flip_cd: float = 0.0

func _ready() -> void:
	super._ready()
	move_speed = arm_speed
	max_health = arm_health
	current_health = max_health
	damage = leap_damage
	lunge_enabled = true
	lunge_min_distance = 0.0      # antes 50: pegado al jugador se quedaba parado sin atacar
	lunge_max_distance = 170.0
	lunge_windup = 0.3
	lunge_speed = 420.0
	lunge_duration = 0.36
	lunge_stun = shake_stun
	lunge_cooldown = 1.6
	_lunge_cooldown_left = randf_range(0.4, 1.0)   # no saltan todos a la vez
	_orbit_sign = 1.0 if randf() < 0.5 else -1.0
	_weave_time = randf() * TAU
	_grip_key = "arm_cling_%d" % get_instance_id()
	_default_modulate = body_tint
	if anim_sprite: anim_sprite.modulate = body_tint

func _exit_tree() -> void:
	_release_grip()
	super._exit_tree()

func die() -> void:
	_cling_left = 0.0
	_release_grip()
	queue_redraw()
	super.die()

# --- Sin golpe normal: solo salta ---

func _on_attack_timer_timeout() -> void:
	pass

# --- Movimiento: zigzag al acercarse, órbita mientras espera el salto ---

func move_towards_target() -> void:
	if not is_instance_valid(target): return
	_apply_chase_velocity()

func _apply_chase_velocity() -> void:
	var dir := get_nav_direction_to_target()
	if dir == Vector2.ZERO:
		velocity = Vector2.ZERO
		return
	var frame_time := get_physics_process_delta_time()
	_weave_time += frame_time
	_orbit_flip_cd -= frame_time
	var side := dir.orthogonal()
	var dist := global_position.distance_to(target.global_position)
	if is_stuck and _orbit_flip_cd <= 0.0:
		_orbit_sign = -_orbit_sign
		_orbit_flip_cd = 0.8
	if dist < orbit_distance and _lunge_cooldown_left > 0.0:
		# Con el salto en enfriamiento no se queda quieto: te rodea.
		velocity = (side * _orbit_sign + dir * 0.2).normalized() * move_speed * 0.85
		return
	velocity = (dir + side * sin(_weave_time * weave_frequency) * weave_amount).normalized() * move_speed

# --- Salto ---

func _process_lunge(delta: float) -> bool:
	if _cling_left > 0.0:
		_process_cling(delta)
		return true
	var busy := super._process_lunge(delta)
	if _lunge_phase == LungePhase.WINDUP: queue_redraw()
	return busy

func _start_lunge_windup() -> void:
	super._start_lunge_windup()
	_play_leap_animation()
	queue_redraw()

func _start_lunge_dash() -> void:
	super._start_lunge_dash()
	queue_redraw()

func _play_leap_animation() -> void:
	if not anim_sprite or not anim_sprite.sprite_frames: return
	var anim := "attack_" + _facing_suffix()
	if not anim_sprite.sprite_frames.has_animation(anim): return
	anim_sprite.speed_scale = 1.0
	anim_sprite.play(anim)
	anim_sprite.frame = 0

# Durante el salto no se pisa la animación de ataque con la de caminar.
func update_animation_state() -> void:
	if _cling_left > 0.0:
		play_animation("cling")
		return
	match _lunge_phase:
		LungePhase.WINDUP, LungePhase.DASH:
			return
		LungePhase.STUN:
			play_animation("idle")
			return
	super.update_animation_state()

# Si conecta, en vez de seguir de largo se aferra. El dash del jugador lo esquiva.
func _apply_lunge_damage() -> void:
	if _lunge_hit or is_dying or not is_instance_valid(target): return
	if target.get("is_dashing") == true: return
	var reached := global_position.distance_to(target.global_position) <= grab_radius
	if not reached:
		for body in attack_area.get_overlapping_bodies():
			if body == target:
				reached = true
				break
	if not reached: return
	_lunge_hit = true
	if target.has_method("take_damage"):
		target.take_damage(damage, "Brazo errante", global_position)
	_start_cling()

func _start_cling() -> void:
	_lunge_phase = LungePhase.NONE
	_cling_left = cling_time
	_cling_tick_left = cling_tick_interval
	velocity = Vector2.ZERO
	_restore_sprite_modulate()
	if is_instance_valid(target):
		_gripped_target = target
		if target.has_method("apply_stun"): target.apply_stun(cling_time + 0.05, _grip_key)
		_grip_overlay = GripOverlay.attach(target, GRIP_SHEET)
	# Con la animación de agarre puesta, el sprite suelto del brazo se esconde.
	if anim_sprite and is_instance_valid(_grip_overlay): anim_sprite.visible = false
	queue_redraw()

func _process_cling(delta: float) -> void:
	if is_dying or not is_instance_valid(target):
		_end_cling()
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
		_end_cling()

func _end_cling() -> void:
	_cling_left = 0.0
	_release_grip()
	_end_lunge()

# Suelta al jugador: quita el stun, la animación de agarre y vuelve a mostrar el sprite del brazo.
func _release_grip() -> void:
	if _gripped_target and is_instance_valid(_gripped_target) and _gripped_target.has_method("release_stun"):
		_gripped_target.release_stun(_grip_key)
	_gripped_target = null
	if is_instance_valid(_grip_overlay): _grip_overlay.release()
	_grip_overlay = null
	if anim_sprite and is_instance_valid(anim_sprite): anim_sprite.visible = true

# Los golpes a un brazo que te tiene agarrado se ven en la animación de agarre.
func take_damage(amount: int, is_crit: bool = false) -> void:
	super.take_damage(amount, is_crit)
	if is_instance_valid(_grip_overlay): _grip_overlay.flash()

# --- Aviso del salto: hasta dónde llega ---

func _draw() -> void:
	if is_dying or _lunge_phase != LungePhase.WINDUP: return
	var k := 1.0 - clampf(_lunge_time_left / maxf(lunge_windup, 0.01), 0.0, 1.0)
	var reach := lunge_speed * lunge_duration
	var end := _lunge_dir * reach
	# El nodo puede estar escalado (élite): se dibuja en píxeles de mundo.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0 / scale.x, 1.0 / scale.y))
	draw_line(Vector2.ZERO, end, Color(1.0, 0.15, 0.1, 0.18 + 0.4 * k), 3.0)
	draw_circle(end, grab_radius * (0.4 + 0.6 * k), Color(1.0, 0.2, 0.1, 0.12 + 0.2 * k))

# Muerte animada con el sprite propio (animación "death"); sin ella, desintegración normal.
func _spawn_pixel_death() -> void:
	if not EnemyDeathAnim.play(self): super._spawn_pixel_death()
