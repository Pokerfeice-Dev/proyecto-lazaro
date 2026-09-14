extends EnemyBase
class_name Carpenter

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
var is_attacking: bool = false
@export var anticipation_time: float = 0.25
var is_anticipating_shot: bool = false
var _anticipation_tween: Tween = null

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_sound: AudioStreamPlayer2D = $Attack_sound

func _ready() -> void:
	super._ready()
	move_speed = 120.0
	max_health = 32
	_setup_shoot_timer()
	current_state = State.WANDER
	_pick_new_wander_direction()
	if attack_sound: attack_sound.bus = "SFX"

func _exit_tree() -> void:
	_cancel_anticipation_tween()

func die() -> void:
	is_anticipating_shot = false
	_restore_sprite_modulate()
	super.die()

func _play_attack_sound() -> void:
	if attack_sound:
		attack_sound.play()



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

func _on_player_alerted() -> void:
	if current_state != State.DEAD:
		player_in_detect_range = true
		_update_logic_state()

func _process_chase() -> void:
	if not target: return
	_update_logic_state()
	if current_state == State.SHOOT: return
	var dir = get_nav_direction_to_target()
	velocity = dir * move_speed

func _process_shoot() -> void:
	velocity = Vector2.ZERO
	if not has_line_of_sight_to_player():
		_update_logic_state()
		return
	if shoot_timer.is_stopped():
		shoot_timer.start(fire_rate)

func _on_shoot_ready() -> void:
	if is_dying or current_state == State.DEAD: return
	if not target: return
	if not has_line_of_sight_to_player():
		_update_logic_state()
		return
	_start_shoot_anticipation()

func _start_shoot_anticipation() -> void:
	if is_dying or current_state == State.DEAD: return
	if is_anticipating_shot or is_attacking: return
	is_anticipating_shot = true
	velocity = Vector2.ZERO
	_face_target()
	_play_anticipation_visuals()
	get_tree().create_timer(anticipation_time).timeout.connect(_on_anticipation_finished, CONNECT_ONE_SHOT)

func _play_anticipation_visuals() -> void:
	if not anim_sprite: return
	_cancel_anticipation_tween()
	_anticipation_tween = create_tween()
	_anticipation_tween.tween_property(anim_sprite, "modulate", Color(2.4, 0.35, 0.35, 1.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_anticipation_finished() -> void:
	if is_dying or current_state == State.DEAD: return
	if not is_anticipating_shot: return
	is_anticipating_shot = false
	_restore_sprite_modulate()
	if not target or not has_line_of_sight_to_player():
		_update_logic_state()
		return
	shoot_at_target()

func _restore_sprite_modulate() -> void:
	_cancel_anticipation_tween()
	if not anim_sprite: return
	anim_sprite.modulate = _default_modulate

func _cancel_anticipation_tween() -> void:
	if not _anticipation_tween: return
	if not _anticipation_tween.is_valid(): return
	_anticipation_tween.kill()
	_anticipation_tween = null

func _face_target() -> void:
	if not target: return
	var dir = (target.global_position - global_position).normalized()
	var suffix = _get_cardinal_direction_suffix(dir)
	_update_directional_flip(dir, suffix)

# --- Señales conectadas desde el Inspector ---

func _on_detect_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_detect_range = true
		alert_to_player()
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
	if player_in_shoot_range and has_line_of_sight_to_player():
		current_state = State.SHOOT
		return
	is_attacking = false
	if is_anticipating_shot:
		is_anticipating_shot = false
		_restore_sprite_modulate()
	if player_in_detect_range or has_detected_player:
		current_state = State.CHASE
		return
	current_state = State.WANDER

# --- Auxiliares y Animaciones ---

func update_sprite_direction() -> void:
	if is_attacking or is_anticipating_shot: return
	if velocity.length() <= 1.0:
		_update_idle_flip()

func update_animation_state() -> void:
	if is_dying or current_state == State.DEAD: return
	if is_attacking or is_anticipating_shot: return
	if velocity.length() > 1.0:
		_process_walk_animation()
		return
	_play_idle_animation()

func _process_walk_animation() -> void:
	var move_dir = velocity.normalized()
	var suffix = _get_cardinal_direction_suffix(move_dir)
	var anim_name = _get_directional_animation_name("walk", move_dir)
	_update_directional_flip(move_dir, suffix)
	play_animation(anim_name)

func _play_idle_animation() -> void:
	_update_idle_flip()
	play_animation("idle")

func play_animation(anim_name: String) -> void:
	if not anim_sprite: return
	if anim_sprite.animation == anim_name and anim_sprite.is_playing(): return
	if not anim_sprite.sprite_frames.has_animation(anim_name): return
	anim_sprite.play(anim_name)

func shoot_at_target() -> void:
	if not target or not projectile_scene: return
	var dir = (target.global_position - global_position).normalized()
	_start_attack_sequence(dir)
	_spawn_projectile(dir)
	_play_attack_sound()

func _spawn_projectile(dir: Vector2) -> void:
	var proj = projectile_scene.instantiate()
	proj.source_name = "Carpenter"
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	proj.setup(dir, damage, "player")

func _start_attack_sequence(dir: Vector2) -> void:
	is_attacking = true
	var suffix = _get_cardinal_direction_suffix(dir)
	var anim_name = _get_directional_animation_name("attack", dir)
	_update_directional_flip(dir, suffix)
	play_animation(anim_name)
	var duration = _get_attack_duration(anim_name)
	get_tree().create_timer(duration).timeout.connect(_on_attack_finished, CONNECT_ONE_SHOT)

func _on_attack_finished() -> void:
	is_anticipating_shot = false
	_restore_sprite_modulate()
	if is_dying or current_state == State.DEAD: return
	is_attacking = false
	if current_state == State.SHOOT:
		_play_idle_animation()

func _get_cardinal_direction_suffix(dir: Vector2) -> String:
	if absf(dir.y) > absf(dir.x):
		if dir.y < 0.0:
			return "up"
		return "down"
	return "side"

func _get_directional_animation_name(prefix: String, dir: Vector2) -> String:
	var suffix = _get_cardinal_direction_suffix(dir)
	var full_name = prefix + "_" + suffix
	if anim_sprite and anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation(full_name):
		return full_name
	return prefix

func _update_directional_flip(dir: Vector2, anim_suffix: String) -> void:
	if not anim_sprite: return
	if anim_suffix == "side":
		anim_sprite.flip_h = dir.x < 0.0
		return
	anim_sprite.flip_h = false

func _update_idle_flip() -> void:
	if not anim_sprite: return
	if not target: return
	var to_player = target.global_position - global_position
	anim_sprite.flip_h = to_player.x < 0.0

func _get_attack_duration(anim_name: String) -> float:
	if not anim_sprite or not anim_sprite.sprite_frames: return 0.25
	if not anim_sprite.sprite_frames.has_animation(anim_name): return 0.25
	var frames = anim_sprite.sprite_frames.get_frame_count(anim_name)
	var speed = anim_sprite.sprite_frames.get_animation_speed(anim_name)
	if speed <= 0.0: return 0.25
	var anim_dur = float(frames) / speed
	return maxf(anim_dur, 0.25)
