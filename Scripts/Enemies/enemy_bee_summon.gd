extends EnemyBase
class_name EnemyBeeSummon

enum State {
	CHASE,
	PREPARE_CHARGE,
	CHARGE,
	COOLDOWN,
	DEAD
}

@export var charge_speed: float = 600.0
@export var charge_duration: float = 0.55
@export var prepare_duration: float = 0.8
@export var cooldown_duration: float = 1.2
@export var min_dist_to_charge: float = 200.0

var current_state: State = State.CHASE
var state_timer: float = 0.0
var charge_direction: Vector2 = Vector2.ZERO
var charge_target_position: Vector2 = Vector2.ZERO
var has_hit_player: bool = false

var charge_line: Line2D = null
@onready var anim_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var attack_area: Area2D = get_node_or_null("AttackArea")

func _ready() -> void:
	super._ready()
	max_health = 35
	current_health = max_health
	move_speed = 220.0
	damage = 12
	
	charge_line = Line2D.new()
	charge_line.width = 3.0
	charge_line.default_color = Color(1.0, 0.1, 0.1, 0.5)
	charge_line.visible = false
	add_child(charge_line)

func _physics_process(delta: float) -> void:
	if is_dying:
		current_state = State.DEAD
		if charge_line:
			charge_line.visible = false
		return
		
	super._physics_process(delta)
	
	if current_state == State.PREPARE_CHARGE or current_state == State.CHARGE or current_state == State.COOLDOWN:
		state_timer -= delta
		if state_timer <= 0.0:
			_advance_state()
			
	if current_state == State.PREPARE_CHARGE and target:
		charge_target_position = target.global_position
		if charge_line:
			charge_line.clear_points()
			charge_line.add_point(Vector2.ZERO)
			charge_line.add_point(to_local(charge_target_position))
			charge_line.visible = true
			
	if current_state == State.CHARGE:
		_check_collision_damage()

func _advance_state() -> void:
	match current_state:
		State.PREPARE_CHARGE:
			_start_charge()
		State.CHARGE:
			_start_cooldown()
		State.COOLDOWN:
			_start_chase()

func _start_prepare() -> void:
	current_state = State.PREPARE_CHARGE
	state_timer = prepare_duration
	velocity = Vector2.ZERO
	if anim_sprite:
		anim_sprite.play("idle")

func _start_charge() -> void:
	current_state = State.CHARGE
	state_timer = charge_duration
	has_hit_player = false
	if charge_line:
		charge_line.visible = false
		
	if target:
		charge_direction = (target.global_position - global_position).normalized()
	else:
		charge_direction = Vector2.LEFT # Default fallback
		
	velocity = charge_direction * charge_speed
	if anim_sprite:
		anim_sprite.play("attack")
		anim_sprite.flip_h = charge_direction.x > 0

func _start_cooldown() -> void:
	current_state = State.COOLDOWN
	state_timer = cooldown_duration
	velocity = Vector2.ZERO
	if anim_sprite:
		anim_sprite.play("idle")

func _start_chase() -> void:
	current_state = State.CHASE
	if anim_sprite:
		anim_sprite.play("walk")

func _check_collision_damage() -> void:
	if has_hit_player or not attack_area: return
	
	var bodies = attack_area.get_overlapping_bodies()
	for b in bodies:
		if b.is_in_group("player") and b.has_method("take_damage"):
			b.take_damage(damage, "Abeja Mutante", global_position)
			has_hit_player = true
			break

func process_movement(delta: float) -> void:
	if is_dying:
		velocity = Vector2.ZERO
		return
		
	match current_state:
		State.CHASE:
			if not target:
				velocity = Vector2.ZERO
				if anim_sprite:
					anim_sprite.play("idle")
				return
				
			var dir = (target.global_position - global_position).normalized()
			velocity = dir * move_speed
			if anim_sprite:
				anim_sprite.play("walk")
				anim_sprite.flip_h = dir.x > 0
				
			if global_position.distance_to(target.global_position) <= min_dist_to_charge:
				_start_prepare()
				
		State.PREPARE_CHARGE:
			velocity = Vector2.ZERO
			
		State.CHARGE:
			velocity = charge_direction * charge_speed
			
		State.COOLDOWN:
			velocity = velocity.lerp(Vector2.ZERO, 8.0 * delta)
