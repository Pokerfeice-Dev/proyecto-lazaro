extends Projectile

var target_node: Node2D = null
var has_target: bool = false
var elapsed_time: float = 0.0

func set_homing_target(target: Node2D) -> void:
	if target and is_instance_valid(target):
		target_node = target
		has_target = true

func _physics_process(delta: float) -> void:
	elapsed_time += delta
	_update_homing(delta)
	global_position += direction * speed * delta

func _update_homing(delta: float) -> void:
	if not has_target:
		return
	if elapsed_time < 0.3:
		return
	_steer_towards_target(delta)

func _steer_towards_target(delta: float) -> void:
	if not target_node or not is_instance_valid(target_node):
		has_target = false
		return
	
	var head_pos = global_position
	var head_node = get_node_or_null("Bee_head")
	if head_node:
		head_pos = head_node.global_position
		
	var target_dir = (target_node.global_position - head_pos).normalized()
	var turn_speed = 6.0
	var angle_to_target = direction.angle_to(target_dir)
	direction = direction.rotated(clampf(angle_to_target, -turn_speed * delta, turn_speed * delta))
	rotation = direction.angle()
