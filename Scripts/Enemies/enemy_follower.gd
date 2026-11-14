class_name EnemyFollower
extends EnemyBase
enum State {
	IDLE,
	CHASE,
	ATTACK,
	DEAD,
	WANDER
}

enum Facing {
	FRONT,
	SIDE,
	BACK
}

var current_state: State = State.WANDER

var wander_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO

@onready var anim_sprite = get_node_or_null("AnimatedSprite2D")

var facing: Facing = Facing.SIDE

var attack_area: Area2D
var attack_timer: Timer
var has_damaged_this_attack: bool = false
@export var attack_range: float = 45.0
@export var anticipation_time: float = 0.22

# Embestida: se frena avisando, se lanza en línea recta y, si falla, queda aturdido.
enum LungePhase {
	NONE,
	WINDUP,
	DASH,
	STUN
}

@export_category("Embestida")
@export var lunge_enabled: bool = true
@export var lunge_min_distance: float = 80.0
@export var lunge_max_distance: float = 170.0
@export var lunge_windup: float = 0.4
@export var lunge_speed: float = 400.0
@export var lunge_duration: float = 0.3
@export var lunge_stun: float = 0.8
@export var lunge_cooldown: float = 2.5

const LUNGE_STUN_TINT := Color(1.4, 1.4, 0.6, 1.0)

var _lunge_phase: LungePhase = LungePhase.NONE
var _lunge_time_left: float = 0.0
var _lunge_cooldown_left: float = 1.0
var _lunge_dir: Vector2 = Vector2.RIGHT
var _lunge_hit: bool = false

var is_anticipating: bool = false
var _anticipation_tween: Tween = null

@onready var attack_sound: AudioStreamPlayer2D = $Attack_sound

func _ready() -> void:
	super._ready()
	if attack_sound: attack_sound.bus = "SFX"
	move_speed = 180.0
	max_health = 48
	detection_radius = 250.0
	_setup_attack_system()
	current_state = State.WANDER
	_pick_new_wander_direction()

func _exit_tree() -> void:
	_cancel_anticipation_tween()

func die() -> void:
	is_anticipating = false
	_lunge_phase = LungePhase.NONE
	_restore_sprite_modulate()
	super.die()

func _spawn_pixel_death() -> void:
	PIXEL_DEATH.spawn_from(_get_sprite(), 0.25)

func _play_attack_sound() -> void:
	if attack_sound:
		attack_sound.play()

func _setup_attack_system() -> void:
	_create_attack_area()
	_create_attack_timer()

func _create_attack_area() -> void:
	attack_area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = attack_range
	collision.shape = shape
	attack_area.add_child(collision)
	add_child(attack_area)

func _create_attack_timer() -> void:
	attack_timer = Timer.new()
	attack_timer.wait_time = 1.0
	attack_timer.one_shot = false
	attack_timer.autostart = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)

func _on_attack_timer_timeout() -> void:
	if current_state == State.DEAD: return
	if current_state == State.ATTACK or is_anticipating: return
	if _lunge_phase != LungePhase.NONE: return
	_check_overlapping_for_attack()

func _check_overlapping_for_attack() -> void:
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			_start_attack_anticipation()
			return

func _start_attack_anticipation() -> void:
	if is_dying or current_state == State.DEAD: return
	if current_state == State.ATTACK or is_anticipating: return
	is_anticipating = true
	velocity = Vector2.ZERO
	_play_anticipation_visuals()
	get_tree().create_timer(anticipation_time).timeout.connect(_on_anticipation_finished, CONNECT_ONE_SHOT)

func _play_anticipation_visuals() -> void:
	if not anim_sprite: return
	_cancel_anticipation_tween()
	_anticipation_tween = create_tween()
	_anticipation_tween.tween_property(anim_sprite, "modulate", Color(2.4, 0.35, 0.35, 1.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_anticipation_finished() -> void:
	if is_dying or current_state == State.DEAD: return
	if not is_anticipating: return
	is_anticipating = false
	_restore_sprite_modulate()
	perform_attack()

func _restore_sprite_modulate() -> void:
	_cancel_anticipation_tween()
	if not anim_sprite: return
	anim_sprite.modulate = _default_modulate

func _cancel_anticipation_tween() -> void:
	if not _anticipation_tween: return
	if not _anticipation_tween.is_valid(): return
	_anticipation_tween.kill()
	_anticipation_tween = null

func perform_attack() -> void:
	if is_dying: return
	current_state = State.ATTACK
	has_damaged_this_attack = false

	anim_sprite.speed_scale = attack_speed
	var attack_anim = "attack_" + _facing_suffix()
	play_animation(attack_anim)
	_play_attack_sound()
	velocity = Vector2.ZERO

	var duration = _get_attack_duration(attack_anim) / attack_speed
	get_tree().create_timer(duration).timeout.connect(_finish_attack, CONNECT_ONE_SHOT)

func _on_animated_sprite_2d_frame_changed() -> void:
	if current_state != State.ATTACK: return
	if has_damaged_this_attack: return

	# El seguidor ataca en el frame central (2)
	if anim_sprite.frame >= 2:
		_apply_damage_to_area()
		has_damaged_this_attack = true

func _apply_damage_to_area() -> void:
	if is_dying: return
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage, "Mutante Seguidor", global_position)

func _get_attack_duration(anim_name: String = "") -> float:
	if not anim_sprite or not anim_sprite.sprite_frames: return 0.6
	if anim_name == "":
		anim_name = anim_sprite.animation
	if not anim_sprite.sprite_frames.has_animation(anim_name): return 0.6
	var fps = anim_sprite.sprite_frames.get_animation_speed(anim_name)
	var frames = anim_sprite.sprite_frames.get_frame_count(anim_name)
	return float(frames) / fps if fps > 0 else 0.6

func _finish_attack() -> void:
	is_anticipating = false
	_restore_sprite_modulate()
	if is_dying:
		current_state = State.DEAD
		return
	anim_sprite.speed_scale = 1.0
	current_state = State.CHASE

func _on_player_alerted() -> void:
	if current_state != State.ATTACK and current_state != State.DEAD:
		current_state = State.CHASE

func process_movement(delta: float) -> void:
	if is_dying:
		current_state = State.DEAD
		return

	if current_state == State.ATTACK or is_anticipating:
		velocity = Vector2.ZERO
		return

	if not target:
		stop_movement()
		return

	if not has_detected_player:
		_process_wander(delta)
		update_animation_state()
		return

	if _process_lunge(delta): return
	move_towards_target()
	update_sprite_direction()
	update_animation_state()

# Devuelve true mientras la embestida controla el movimiento.
func _process_lunge(delta: float) -> bool:
	_lunge_cooldown_left = maxf(0.0, _lunge_cooldown_left - delta)
	match _lunge_phase:
		LungePhase.WINDUP:
			velocity = Vector2.ZERO
			_lunge_time_left -= delta
			if _lunge_time_left <= 0.0: _start_lunge_dash()
			return true
		LungePhase.DASH:
			_lunge_time_left -= delta
			velocity = _lunge_dir * lunge_speed
			_apply_lunge_damage()
			update_animation_state()
			if _lunge_time_left <= 0.0 or is_on_wall(): _start_lunge_stun()
			return true
		LungePhase.STUN:
			velocity = Vector2.ZERO
			_lunge_time_left -= delta
			if _lunge_time_left <= 0.0: _end_lunge()
			return true
	if _can_start_lunge():
		_start_lunge_windup()
		return true
	return false

func _can_start_lunge() -> bool:
	if not lunge_enabled or _lunge_cooldown_left > 0.0: return false
	if current_state == State.ATTACK or is_anticipating: return false
	if not is_instance_valid(target): return false
	var dist = global_position.distance_to(target.global_position)
	if dist < lunge_min_distance or dist > lunge_max_distance: return false
	return _can_walk_segment(global_position, target.global_position)

func _start_lunge_windup() -> void:
	_lunge_phase = LungePhase.WINDUP
	_lunge_time_left = lunge_windup
	_lunge_dir = global_position.direction_to(target.global_position)
	velocity = Vector2.ZERO
	_update_facing_from_direction(_lunge_dir)
	play_animation("idle")
	_play_anticipation_visuals()

func _start_lunge_dash() -> void:
	_lunge_phase = LungePhase.DASH
	_lunge_time_left = lunge_duration
	_lunge_hit = false
	_play_attack_sound()

func _apply_lunge_damage() -> void:
	if _lunge_hit or is_dying: return
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage, "Mutante Seguidor", global_position)
			_lunge_hit = true
			return

func _start_lunge_stun() -> void:
	_lunge_phase = LungePhase.STUN
	_lunge_time_left = lunge_stun
	velocity = Vector2.ZERO
	_restore_sprite_modulate()
	play_animation("idle")
	if anim_sprite: anim_sprite.modulate = LUNGE_STUN_TINT

func _end_lunge() -> void:
	_lunge_phase = LungePhase.NONE
	_lunge_cooldown_left = lunge_cooldown
	_restore_sprite_modulate()

func _process_wander(delta: float) -> void:
	current_state = State.WANDER
	wander_timer -= delta
	if wander_timer <= 0:
		_pick_new_wander_direction()
	velocity = wander_direction * (move_speed * 0.4)
	if anim_sprite:
		_update_facing_from_direction(wander_direction)

func _pick_new_wander_direction() -> void:
	wander_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	wander_timer = randf_range(1.0, 3.0)

func stop_movement() -> void:
	velocity = Vector2.ZERO
	play_animation("idle")

func move_towards_target() -> void:
	var dist = global_position.distance_to(target.global_position)
	if dist <= attack_range * 0.8:
		velocity = Vector2.ZERO
		return
	_apply_chase_velocity()

func _apply_chase_velocity() -> void:
	var dir = get_nav_direction_to_target()
	velocity = dir * move_speed

func update_sprite_direction() -> void:
	if not anim_sprite or not target: return
	var dir = velocity.normalized() if velocity.length() > 10.0 else (target.global_position - global_position).normalized()
	_update_facing_from_direction(dir)

# Decide si el sprite debe mirar de frente, de perfil o de espaldas segun el
# eje dominante del movimiento, y aplica el flip horizontal correcto para el
# nuevo arte del perro (que mira a la derecha por defecto).
func _update_facing_from_direction(dir: Vector2) -> void:
	if dir.length() < 0.001:
		return
	if absf(dir.y) > absf(dir.x):
		facing = Facing.BACK if dir.y < 0 else Facing.FRONT
	else:
		facing = Facing.SIDE
	anim_sprite.flip_h = dir.x < 0

func _facing_suffix() -> String:
	match facing:
		Facing.FRONT:
			return "front"
		Facing.BACK:
			return "back"
		_:
			return "side"

func update_animation_state() -> void:
	if velocity.length() > 0:
		play_animation("walk_" + _facing_suffix())
		return
	play_animation("idle")

func play_animation(anim_name: String) -> void:
	if not anim_sprite: return
	if anim_sprite.animation == anim_name: return
	if not anim_sprite.sprite_frames.has_animation(anim_name): return
	anim_sprite.play(anim_name)
