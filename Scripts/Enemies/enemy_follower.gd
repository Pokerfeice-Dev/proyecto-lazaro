extends EnemyBase
class_name EnemyFollower

enum State {
	IDLE,
	CHASE,
	ATTACK,
	DEAD,
	WANDER
}

var current_state: State = State.WANDER
var has_detected_player: bool = false
@export var detection_radius: float = 250.0

var wander_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO

@onready var anim_sprite = get_node_or_null("AnimatedSprite2D")

var attack_area: Area2D
var attack_timer: Timer
var has_damaged_this_attack: bool = false
@export var attack_range: float = 45.0

func _ready() -> void:
	super._ready()
	move_speed = 180.0
	max_health = 60
	_setup_attack_system()
	current_state = State.WANDER
	_pick_new_wander_direction()

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
	attack_timer.one_shot = true
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
	play_animation("attack")
	velocity = Vector2.ZERO
	
	var duration = _get_attack_duration() / attack_speed
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
			body.take_damage(damage)

func _get_attack_duration() -> float:
	if not anim_sprite or not anim_sprite.sprite_frames: return 0.6
	if not anim_sprite.sprite_frames.has_animation("attack"): return 0.6
	var fps = anim_sprite.sprite_frames.get_animation_speed("attack")
	var frames = anim_sprite.sprite_frames.get_frame_count("attack")
	return float(frames) / fps if fps > 0 else 0.6

func _finish_attack() -> void:
	if is_dying:
		current_state = State.DEAD
		return
	anim_sprite.speed_scale = 1.0
	current_state = State.CHASE
	attack_timer.start()

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
		if global_position.distance_to(target.global_position) <= detection_radius:
			has_detected_player = true
			current_state = State.CHASE
		else:
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
		anim_sprite.flip_h = velocity.x > 0

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
		# Intentar atacar si el timer lo permite
		if attack_timer.is_stopped():
			perform_attack()
		return
	_apply_chase_velocity()

func _apply_chase_velocity() -> void:
	var dir = (target.global_position - global_position).normalized()
	velocity = dir * move_speed

func update_sprite_direction() -> void:
	if not anim_sprite or not target: return
	var dir = (target.global_position - global_position).normalized()
	anim_sprite.flip_h = dir.x > 0

func update_animation_state() -> void:
	if velocity.length() > 0:
		play_animation("walk")
		return
	play_animation("idle")

func play_animation(anim_name: String) -> void:
	if not anim_sprite: return
	if anim_sprite.animation == anim_name: return
	if not anim_sprite.sprite_frames.has_animation(anim_name): return
	anim_sprite.play(anim_name)
