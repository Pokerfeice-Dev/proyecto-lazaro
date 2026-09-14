extends EnemyBase
class_name Mecha

enum State {
	IDLE,
	CHASE,
	ATTACK,
	DEAD,
	WANDER
}

var current_state: State = State.WANDER

var wander_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $Area_attack
@onready var attack_sound: AudioStreamPlayer2D = $Attack_sound
@onready var attack_fx: AnimatedSprite2D = $Attack_fx
@onready var attack_hydraulic: AudioStreamPlayer2D = get_node_or_null("Attack_hydraulic")
@onready var attack_explosion: AudioStreamPlayer2D = get_node_or_null("Attack_Explosion")
@onready var attack_light: PointLight2D = get_node_or_null("PointLight2D")

@export var attack_range: float = 70.0
@export var slam_radius: float = 48.0
@export var slam_offset: Vector2 = Vector2(0, 4)

var attack_cooldown_timer: Timer
var has_damaged_this_attack: bool = false
var _is_charging_attack: bool = false
var _can_attack: bool = true
var _light_target_energy: float = 2.0
var _light_tween: Tween = null

func _ready() -> void:
	super._ready()
	is_heavy_stepper = true
	_enemy_footstep_interval = 0.48
	move_speed = 70.0
	max_health = 144
	damage = 25
	detection_radius = 300.0
	_setup_audio_buses()
	_setup_attack_light()
	_setup_attack_fx()
	_setup_attack_cooldown_timer()
	_connect_animation_finished()
	current_state = State.WANDER
	_pick_new_wander_direction()

func _exit_tree() -> void:
	_kill_attack_light()
	_stop_hydraulic_sound()
	_hide_telegraph()

func _get_footstep_offset() -> Vector2:
	return Vector2(0, 14)

func _setup_attack_light() -> void:
	if not attack_light: return
	if attack_light.energy > 0.0:
		_light_target_energy = attack_light.energy
	attack_light.energy = 0.0
	attack_light.enabled = false

func _turn_on_attack_light() -> void:
	if not attack_light: return
	_cancel_light_tween()
	attack_light.enabled = true
	attack_light.energy = 0.0
	_light_tween = create_tween()
	_light_tween.tween_property(attack_light, "energy", _light_target_energy, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _turn_off_attack_light() -> void:
	if not attack_light: return
	if not attack_light.enabled: return
	_cancel_light_tween()
	_light_tween = create_tween()
	_light_tween.tween_property(attack_light, "energy", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_light_tween.finished.connect(_on_light_turned_off)

func _on_light_turned_off() -> void:
	if not attack_light: return
	attack_light.enabled = false

func _cancel_light_tween() -> void:
	if not _light_tween: return
	if not _light_tween.is_valid(): return
	_light_tween.kill()
	_light_tween = null

func _kill_attack_light() -> void:
	if not attack_light: return
	_cancel_light_tween()
	attack_light.energy = 0.0
	attack_light.enabled = false

func _setup_audio_buses() -> void:
	_set_bus_safe(attack_hydraulic, "SFX")
	_set_bus_safe(attack_explosion, "SFX")
	_set_bus_safe(attack_sound, "SFX")

func _set_bus_safe(player: AudioStreamPlayer2D, bus_name: String) -> void:
	if not player: return
	player.bus = bus_name

func _play_attack_sound() -> void:
	if not attack_sound: return
	attack_sound.play()

func _play_hydraulic_sound() -> void:
	if not attack_hydraulic: return
	attack_hydraulic.play()

func _stop_hydraulic_sound() -> void:
	if not attack_hydraulic: return
	if not attack_hydraulic.playing: return
	attack_hydraulic.stop()

func _play_explosion_sound() -> void:
	if attack_explosion:
		attack_explosion.play()
		return
	_play_attack_sound()

func _setup_attack_fx() -> void:
	if not attack_fx: return
	attack_fx.hide()
	attack_fx.stop()
	attack_fx.position = slam_offset
	if attack_fx.sprite_frames:
		attack_fx.sprite_frames.set_animation_loop("fx_attack", false)
	attack_fx.animation_finished.connect(_on_attack_fx_finished)

func _on_attack_fx_finished() -> void:
	if not attack_fx: return
	attack_fx.hide()
	attack_fx.stop()

func _setup_attack_cooldown_timer() -> void:
	attack_cooldown_timer = Timer.new()
	attack_cooldown_timer.wait_time = 2.0
	attack_cooldown_timer.one_shot = true
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_ready)
	add_child(attack_cooldown_timer)

func _start_attack_cooldown() -> void:
	_can_attack = false
	attack_cooldown_timer.start(2.0)

func _on_attack_cooldown_ready() -> void:
	_can_attack = true
	_check_immediate_attack()

func _check_immediate_attack() -> void:
	if is_dying or current_state == State.DEAD: return
	if current_state == State.ATTACK: return
	if not target: return
	var dist = global_position.distance_to(target.global_position)
	if dist <= attack_range:
		perform_attack()

func _connect_animation_finished() -> void:
	if not anim_sprite: return
	anim_sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	if current_state != State.ATTACK: return
	if anim_sprite.animation != "attack": return
	if not has_damaged_this_attack:
		_trigger_ground_slam()
	_finish_attack()

func _pick_new_wander_direction() -> void:
	wander_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	wander_timer = randf_range(2.0, 5.0)

# --- Hyper-Armor e Inmunidad a Interrupciones en Ataque ---

func apply_knockback(force: float, direction: Vector2) -> void:
	if current_state == State.ATTACK: return
	super.apply_knockback(force, direction)

func take_damage(amount: int, is_crit: bool = false) -> void:
	super.take_damage(amount, is_crit)
	if current_state == State.ATTACK:
		hit_stun_timer = 0.0
		velocity = Vector2.ZERO
		knockback_velocity = Vector2.ZERO

func die() -> void:
	_kill_attack_light()
	_stop_hydraulic_sound()
	_hide_telegraph()
	super.die()

# --- Lógica de Combate ---

func _on_player_alerted() -> void:
	if current_state != State.ATTACK and current_state != State.DEAD:
		current_state = State.CHASE

func _on_detect_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		alert_to_player()

func _on_area_attack_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	if not _can_attack: return
	if current_state == State.ATTACK: return
	_try_attack(body)

func _try_attack(_body: Node2D) -> void:
	if is_dying or current_state == State.DEAD: return
	if current_state == State.ATTACK: return
	if not _can_attack: return
	perform_attack()

func perform_attack() -> void:
	if is_dying or current_state == State.DEAD: return
	if current_state == State.ATTACK: return
	
	current_state = State.ATTACK
	has_damaged_this_attack = false
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	
	_kill_attack_light()
	_is_charging_attack = true
	queue_redraw()
	_play_hydraulic_sound()
	
	anim_sprite.speed_scale = attack_speed
	anim_sprite.play("attack")
	anim_sprite.frame = 0
	
	var duration = (_get_anim_duration("attack") / attack_speed) + 0.15
	get_tree().create_timer(duration).timeout.connect(_on_attack_timeout, CONNECT_ONE_SHOT)

func _on_attack_timeout() -> void:
	if current_state != State.ATTACK: return
	if not has_damaged_this_attack:
		_trigger_ground_slam()
	_finish_attack()

func _on_animated_sprite_2d_frame_changed() -> void:
	if current_state != State.ATTACK: return
	if anim_sprite.animation != "attack": return
	
	if anim_sprite.frame < 8:
		queue_redraw()
		return
	
	if not has_damaged_this_attack:
		_trigger_ground_slam()

func _trigger_ground_slam() -> void:
	has_damaged_this_attack = true
	_stop_hydraulic_sound()
	_hide_telegraph()
	_play_explosion_sound()
	_play_slam_fx()
	_turn_on_attack_light()
	_apply_damage_to_area()
	_shake_ground_impact()

func _play_slam_fx() -> void:
	if not attack_fx: return
	attack_fx.position = slam_offset
	attack_fx.show()
	attack_fx.frame = 0
	attack_fx.play("fx_attack")

func _apply_damage_to_area() -> void:
	var bodies = attack_area.get_overlapping_bodies()
	var player_hit = false
	for body in bodies:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage, "Mecha", global_position)
			player_hit = true
	if player_hit: return
	_apply_distance_damage_fallback()

func _apply_distance_damage_fallback() -> void:
	if not target or not target.is_in_group("player"): return
	var center = global_position + slam_offset
	if center.distance_to(target.global_position) > slam_radius: return
	if target.has_method("take_damage"):
		target.take_damage(damage, "Mecha", global_position)

func _shake_ground_impact() -> void:
	if not target: return
	if not target.has_method("apply_custom_camera_shake"): return
	var dist = global_position.distance_to(target.global_position)
	if dist <= slam_radius * 2.8:
		target.apply_custom_camera_shake(7.0, 0.25)

# --- Telégrafo de Ataque en el Suelo ---

func _draw() -> void:
	if not _is_charging_attack: return
	_draw_attack_telegraph()

func _draw_attack_telegraph() -> void:
	var progress = _get_telegraph_progress()
	var outer_color = Color(1.0, 0.2, 0.15, 0.65)
	var fill_color = Color(1.0, 0.15, 0.1, 0.16)
	var ring_color = Color(1.0, 0.85, 0.2, 0.85)
	var expanding_fill = Color(1.0, 0.25, 0.1, 0.3)
	
	draw_circle(slam_offset, slam_radius, fill_color)
	draw_arc(slam_offset, slam_radius, 0, TAU, 36, outer_color, 2.0)
	
	var current_radius = slam_radius * progress
	if current_radius > 2.0:
		draw_circle(slam_offset, current_radius, expanding_fill)
		draw_arc(slam_offset, current_radius, 0, TAU, 36, ring_color, 2.0)

func _get_telegraph_progress() -> float:
	if not anim_sprite: return 0.0
	return clampf(float(anim_sprite.frame) / 8.0, 0.0, 1.0)

func _hide_telegraph() -> void:
	_is_charging_attack = false
	queue_redraw()

func _finish_attack() -> void:
	if is_dying: return
	_stop_hydraulic_sound()
	_hide_telegraph()
	_turn_off_attack_light()
	anim_sprite.speed_scale = 1.0
	current_state = State.CHASE
	_start_attack_cooldown()

# --- Movimiento ---

func process_movement(delta: float) -> void:
	if is_dying:
		_kill_attack_light()
		_stop_hydraulic_sound()
		_hide_telegraph()
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
	if dist <= attack_range:
		if _can_attack:
			perform_attack()
			return
		velocity = Vector2.ZERO
		return
	var dir = get_nav_direction_to_target()
	velocity = dir * move_speed

func update_sprite_direction() -> void:
	if current_state == State.ATTACK: return
	if not target: return
	var dir = velocity.normalized() if velocity.length() > 10.0 else (target.global_position - global_position).normalized()
	anim_sprite.flip_h = dir.x < 0.0

func update_animation_state() -> void:
	if current_state == State.ATTACK: return
	if velocity.length() > 5.0:
		_process_walk_animation()
		return
	play_animation("idle")

func _process_walk_animation() -> void:
	var move_dir = velocity.normalized()
	if absf(move_dir.y) > absf(move_dir.x):
		if move_dir.y < 0.0:
			play_animation("walk_up")
			return
		play_animation("walk_down")
		return
	play_animation("walk_side")

func play_animation(anim_name: String) -> void:
	if not anim_sprite: return
	if anim_sprite.animation == anim_name and anim_sprite.is_playing(): return
	if not anim_sprite.sprite_frames.has_animation(anim_name): return
	anim_sprite.play(anim_name)

func _get_anim_duration(anim_name: String) -> float:
	if not anim_sprite or not anim_sprite.sprite_frames: return 0.8
	var frames = anim_sprite.sprite_frames.get_frame_count(anim_name)
	var speed = anim_sprite.sprite_frames.get_animation_speed(anim_name)
	return float(frames) / speed if speed > 0 else 0.8
