extends EnemyBase
class_name EnemyShooter

enum State {
	IDLE,
	CHASE,
	SHOOT,
	DEAD,
	WANDER
}
var current_state: State = State.WANDER

var wander_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO

@export var fire_rate: float = 1.5
@export var projectile_scene: PackedScene = preload("res://Scenes/Enemies/enemy_shooter_projectile.tscn")

var shoot_timer: Timer
var player_in_shoot_range: bool = false
var player_in_detect_range: bool = false

func _ready() -> void:
	super._ready()
	move_speed = 120.0
	max_health = 40
	_setup_shoot_timer()
	current_state = State.WANDER
	_pick_new_wander_direction()

func _setup_shoot_timer() -> void:
	shoot_timer = Timer.new()
	shoot_timer.one_shot = true
	add_child(shoot_timer)
	shoot_timer.timeout.connect(_on_shoot_ready)

func _pick_new_wander_direction() -> void:
	wander_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	wander_timer = randf_range(1.0, 3.0)

func process_movement(delta: float) -> void:
	if is_dying:
		current_state = State.DEAD
		return
		
	match current_state:
		State.WANDER:
			_process_wander(delta)
		State.CHASE:
			_process_chase()
		State.SHOOT:
			_process_shoot()
		State.IDLE:
			velocity = Vector2.ZERO
	
	update_animation_state()
	update_sprite_direction()

func _process_wander(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0:
		_pick_new_wander_direction()
	velocity = wander_direction * (move_speed * 0.4)

func _process_chase() -> void:
	if not target: return
	var dir = (target.global_position - global_position).normalized()
	velocity = dir * move_speed

func _process_shoot() -> void:
	velocity = Vector2.ZERO
	if shoot_timer.is_stopped():
		shoot_timer.start(fire_rate)

func _on_shoot_ready() -> void:
	if is_dying or current_state == State.DEAD: return
	if not target: return
	# Solo disparar si el jugador sigue en rango (opcional, pero recomendado)
	shoot_at_target()

# --- Señales conectadas desde el Inspector ---

func _on_detect_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_detect_range = true
		_update_logic_state()

func _on_detect_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_detect_range = false
		_update_logic_state()

func _on_shoot_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_shoot_range = true
		_update_logic_state()

func _on_shoot_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_shoot_range = false
		_update_logic_state()

func _update_logic_state() -> void:
	if player_in_shoot_range:
		current_state = State.SHOOT
	elif player_in_detect_range:
		current_state = State.CHASE
	else:
		current_state = State.WANDER

# --- Auxiliares ---

func update_sprite_direction() -> void:
	var anim_sprite = get_node_or_null("AnimatedSprite2D")
	if not anim_sprite or not target: return
	var dir = (target.global_position - global_position).normalized()
	anim_sprite.flip_h = dir.x > 0

func update_animation_state() -> void:
	if velocity.length() > 1.0:
		play_animation("walk")
	else:
		play_animation("idle")

func play_animation(anim_name: String) -> void:
	var anim_sprite = get_node_or_null("AnimatedSprite2D")
	if not anim_sprite: return
	if anim_sprite.animation == anim_name: return
	if not anim_sprite.sprite_frames.has_animation(anim_name): return
	anim_sprite.play(anim_name)

func shoot_at_target() -> void:
	if not target or not projectile_scene: return
	var dir = (target.global_position - global_position).normalized()
	var proj = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	proj.setup(dir, damage, "player")
