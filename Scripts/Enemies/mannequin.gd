extends EnemyBase
class_name Mannequin

signal hit_received()

func _ready() -> void:
	super._ready()
	move_speed = 0.0
	max_health = 9999
	current_health = max_health
	
	# Hide the health bar for the dummy target
	var bar = get_node_or_null("HealthBar")
	if bar:
		bar.visible = false

func process_movement(_delta: float) -> void:
	# Stay completely static
	velocity = Vector2.ZERO

func take_damage(amount: int, is_crit: bool = false) -> void:
	if is_dying:
		return
	
	hit_stun_timer = 0.15
	_show_damage_text(amount, is_crit)
	_flash_red()
	
	# Emit hit signal for the tutorial logic
	hit_received.emit()
	
	# Restore health immediately so it never dies
	current_health = max_health
	_update_health_bar()

func _check_death() -> void:
	# Overridden to prevent death checks
	pass
