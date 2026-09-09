extends EnemyBase
class_name EnemySummoner

enum State {
	IDLE,
	CHASE,
	SUMMON,
	DEAD
}

@export var summon_cooldown: float = 3.5
@export var min_chase_dist: float = 180.0
@export var max_chase_dist: float = 320.0
@export var bee_scene: PackedScene = preload("res://Scenes/Enemies/Enemy_bee_summon.tscn")

var current_state: State = State.CHASE
var active_summons: Array[Node2D] = []
var summon_timer: float = 1.0 # First summon occurs quickly

@onready var anim_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var summon_anim: AnimatedSprite2D = get_node_or_null("Summon_anim")
@onready var attack_light: PointLight2D = get_node_or_null("Attack_light")

var _light_tween: Tween = null

func _ready() -> void:
	super._ready()
	max_health = 64
	current_health = max_health
	move_speed = 120.0
	
	if attack_light:
		attack_light.enabled = false
		attack_light.energy = 0.0
		
	if summon_anim:
		summon_anim.hide()

func _physics_process(delta: float) -> void:
	if is_dying:
		current_state = State.DEAD
		return
		
	super._physics_process(delta)
	
	if current_state == State.SUMMON:
		return
		
	_handle_summoning(delta)

func _handle_summoning(delta: float) -> void:
	# Clean up any freed nodes from active_summons
	var valid_summons: Array[Node2D] = []
	for s in active_summons:
		if is_instance_valid(s):
			valid_summons.append(s)
	active_summons = valid_summons

	if active_summons.size() < 2:
		summon_timer -= delta
		if summon_timer <= 0.0:
			_start_summon()

func _start_summon() -> void:
	current_state = State.SUMMON
	velocity = Vector2.ZERO
	if anim_sprite:
		anim_sprite.play("attack")
		
	_trigger_attack_light_fade_in()
		
	if summon_anim:
		summon_anim.show()
		summon_anim.play("summon")
		if not summon_anim.animation_finished.is_connected(_on_summon_animation_finished):
			summon_anim.animation_finished.connect(_on_summon_animation_finished, CONNECT_ONE_SHOT)
	elif anim_sprite and anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation("attack"):
		if not anim_sprite.animation_finished.is_connected(_on_summon_animation_finished):
			anim_sprite.animation_finished.connect(_on_summon_animation_finished, CONNECT_ONE_SHOT)
	else:
		_on_summon_animation_finished()

func _trigger_attack_light_fade_in() -> void:
	if not attack_light: return
	if _light_tween and _light_tween.is_valid():
		_light_tween.kill()
		
	attack_light.enabled = true
	attack_light.energy = 0.0
	_light_tween = create_tween()
	_light_tween.tween_property(attack_light, "energy", 1.4, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _trigger_attack_light_fade_out() -> void:
	if not attack_light: return
	if _light_tween and _light_tween.is_valid():
		_light_tween.kill()
		
	_light_tween = create_tween()
	_light_tween.tween_property(attack_light, "energy", 0.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_light_tween.chain().tween_callback(func():
		if is_instance_valid(attack_light):
			attack_light.enabled = false
	)

func _on_summon_animation_finished() -> void:
	if summon_anim:
		summon_anim.hide()
	_trigger_attack_light_fade_out()
	_spawn_bee()

func _spawn_bee() -> void:
	if is_dying:
		current_state = State.DEAD
		return
		
	current_state = State.CHASE
	summon_timer = summon_cooldown
	
	if not bee_scene: return
	var bee = bee_scene.instantiate()
	bee.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	
	if bee.has_signal("enemy_died"):
		bee.enemy_died.connect(_on_bee_died)
		
	get_parent().add_child(bee)
	active_summons.append(bee)

func _on_bee_died(bee: EnemyBase) -> void:
	active_summons.erase(bee)

func _play_walk_animation(dir: Vector2) -> void:
	if not anim_sprite: return
	if absf(dir.y) > absf(dir.x):
		if dir.y > 0:
			anim_sprite.play("walk_down")
			anim_sprite.flip_h = false
		else:
			anim_sprite.play("walk_up")
			anim_sprite.flip_h = false
	else:
		anim_sprite.play("walk_side")
		anim_sprite.flip_h = dir.x < 0

func process_movement(delta: float) -> void:
	if is_dying or current_state == State.SUMMON:
		velocity = Vector2.ZERO
		return
		
	if not target:
		velocity = Vector2.ZERO
		if anim_sprite:
			anim_sprite.play("idle")
		return
		
	var dist = global_position.distance_to(target.global_position)
	var has_los = has_line_of_sight_to_player()
	
	if not has_los or dist > max_chase_dist or is_stuck:
		_process_summoner_chase()
		return
		
	if dist < min_chase_dist:
		_process_summoner_retreat()
		return
		
	_process_summoner_hover(delta)

func _process_summoner_chase() -> void:
	var dir = get_nav_direction_to_target()
	velocity = dir * move_speed
	_play_walk_animation(dir)

func _process_summoner_retreat() -> void:
	var dir = (global_position - target.global_position).normalized()
	velocity = dir * (move_speed * 0.8)
	_play_walk_animation(dir)

func _process_summoner_hover(delta: float) -> void:
	velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)
	if velocity.length() > 20.0:
		_play_walk_animation(velocity.normalized())
		return
	if anim_sprite:
		anim_sprite.play("idle")
