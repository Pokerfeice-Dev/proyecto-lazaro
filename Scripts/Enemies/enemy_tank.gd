extends EnemyBase
class_name EnemyTank

enum State {
	IDLE,
	CHASE,
	ATTACK,
	DEAD,
	WANDER
}

var current_state: State = State.WANDER
var has_detected_player: bool = false
@export var detection_radius: float = 300.0

var wander_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO

@onready var anim_sprite = $AnimatedSprite2D
@onready var attack_area = $Area_attack

var attack_timer: Timer
var has_damaged_this_attack: bool = false
@export var attack_range: float = 70.0

func _ready() -> void:
	super._ready()
	move_speed = 70.0
	max_health = 180
	damage = 25
	_setup_attack_timer()
	current_state = State.WANDER
	_pick_new_wander_direction()

func _setup_attack_timer() -> void:
	attack_timer = Timer.new()
	attack_timer.wait_time = 2.5
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)

func _pick_new_wander_direction() -> void:
	wander_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	wander_timer = randf_range(2.0, 5.0)

# --- Lógica de Combate ---

func _on_detect_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		has_detected_player = true
		current_state = State.CHASE

func _on_area_attack_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_try_attack(body)

func _try_attack(_body: Node2D) -> void:
	if is_dying or current_state == State.DEAD: return
	if current_state == State.ATTACK: return
	if not attack_timer.is_stopped(): return
	
	perform_attack()

func perform_attack() -> void:
	if is_dying: return
	current_state = State.ATTACK
	has_damaged_this_attack = false
	
	anim_sprite.speed_scale = attack_speed
	play_animation("attack")
	velocity = Vector2.ZERO
	
	var duration = _get_anim_duration("attack") / attack_speed
	get_tree().create_timer(duration).timeout.connect(_finish_attack, CONNECT_ONE_SHOT)

func _on_animated_sprite_2d_frame_changed() -> void:
	if current_state != State.ATTACK: return
	if has_damaged_this_attack: return
	
	# El ataque se produce en el frame 3 o 4 (índices 2 o 3 si empieza en 0)
	if anim_sprite.frame >= 2:
		_apply_damage_to_area()
		has_damaged_this_attack = true

func _apply_damage_to_area() -> void:
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage)

func _finish_attack() -> void:
	if is_dying: return
	anim_sprite.speed_scale = 1.0
	current_state = State.CHASE
	attack_timer.start()

func _on_attack_timer_timeout() -> void:
	if is_dying: return
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			_try_attack(body)
			return

# --- Movimiento ---

func process_movement(delta: float) -> void:
	if is_dying:
		current_state = State.DEAD
		return
	
	if current_state == State.ATTACK:
		velocity = Vector2.ZERO
		return
		
	if not target:
		velocity = Vector2.ZERO
		play_animation("idle")
		return

	if not has_detected_player:
		_process_wander(delta)
	else:
		_process_chase()
		
	update_sprite_direction()
	update_animation_state()

func _process_wander(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0:
		_pick_new_wander_direction()
	velocity = wander_direction * (move_speed * 0.5)

func _process_chase() -> void:
	var dist = global_position.distance_to(target.global_position)
	if dist <= attack_range * 0.6:
		velocity = Vector2.ZERO
		return
	var dir = (target.global_position - global_position).normalized()
	velocity = dir * move_speed

func update_sprite_direction() -> void:
	if not target: return
	var dir = (target.global_position - global_position).normalized()
	anim_sprite.flip_h = dir.x > 0

func update_animation_state() -> void:
	if velocity.length() > 5.0:
		play_animation("walk")
	else:
		play_animation("idle")

func play_animation(anim_name: String) -> void:
	if not anim_sprite: return
	if anim_sprite.animation == anim_name: return
	if not anim_sprite.sprite_frames.has_animation(anim_name): return
	anim_sprite.play(anim_name)

func _get_anim_duration(anim_name: String) -> float:
	if not anim_sprite or not anim_sprite.sprite_frames: return 0.8
	var frames = anim_sprite.sprite_frames.get_frame_count(anim_name)
	var speed = anim_sprite.sprite_frames.get_animation_speed(anim_name)
	return float(frames) / speed if speed > 0 else 0.8
