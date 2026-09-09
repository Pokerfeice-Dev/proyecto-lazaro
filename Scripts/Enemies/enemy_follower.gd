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

@onready var attack_sound: AudioStreamPlayer2D = $Attack_sound

func _ready() -> void:
	super._ready()
	move_speed = 180.0
	max_health = 48
	detection_radius = 250.0
	_setup_attack_system()
	current_state = State.WANDER
	_pick_new_wander_direction()

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
	if current_state == State.ATTACK: return
	_check_overlapping_for_attack()

func _check_overlapping_for_attack() -> void:
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			perform_attack()
			return

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

	if current_state == State.ATTACK:
		velocity = Vector2.ZERO
		return

	if not target:
		stop_movement()
		return

	if not has_detected_player:
		_process_wander(delta)
		update_animation_state()
		return

	move_towards_target()
	update_sprite_direction()
	update_animation_state()

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
