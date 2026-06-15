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

func _ready() -> void:
	super._ready()
	max_health = 80
	current_health = max_health
	move_speed = 120.0
	
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
		anim_sprite.play("idle")
		
	if summon_anim:
		summon_anim.show()
		summon_anim.play("summon")
		if not summon_anim.animation_finished.is_connected(_on_summon_animation_finished):
			summon_anim.animation_finished.connect(_on_summon_animation_finished, CONNECT_ONE_SHOT)
	else:
		_spawn_bee()

func _on_summon_animation_finished() -> void:
	if summon_anim:
		summon_anim.hide()
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

func process_movement(_delta: float) -> void:
	if is_dying or current_state == State.SUMMON:
		velocity = Vector2.ZERO
		return
		
	if not target:
		velocity = Vector2.ZERO
		if anim_sprite:
			anim_sprite.play("idle")
		return
		
	var dist = global_position.distance_to(target.global_position)
	var dir = (target.global_position - global_position).normalized()
	
	if dist > max_chase_dist:
		# Chase closer
		velocity = dir * move_speed
		if anim_sprite:
			anim_sprite.play("walk")
			anim_sprite.flip_h = dir.x > 0
	elif dist < min_chase_dist:
		# Back off
		velocity = -dir * (move_speed * 0.8)
		if anim_sprite:
			anim_sprite.play("walk")
			anim_sprite.flip_h = -dir.x > 0
	else:
		# Hover in range
		velocity = velocity.lerp(Vector2.ZERO, 5.0 * _delta)
		if anim_sprite:
			if velocity.length() > 20.0:
				anim_sprite.play("walk")
			else:
				anim_sprite.play("idle")
			anim_sprite.flip_h = dir.x > 0
