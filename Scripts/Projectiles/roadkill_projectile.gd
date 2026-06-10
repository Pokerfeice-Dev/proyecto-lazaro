extends Projectile

var bounces_left: int = 3

func _on_body_entered(body: Node2D) -> void:
	if target_group != "" and body.is_in_group(target_group):
		_handle_enemy_collision(body)
		return
	_handle_other_collision(body)

func _handle_enemy_collision(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, is_crit)
	_decrement_piercing_or_free()

func _decrement_piercing_or_free() -> void:
	if piercing > 0:
		piercing -= 1
		return
	queue_free()

func _handle_other_collision(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("enemy"):
		return
	_handle_wall_bounce()

func _handle_wall_bounce() -> void:
	if bounces_left <= 0:
		queue_free()
		return
	_bounce_off_wall()

func _bounce_off_wall() -> void:
	var space_state = get_world_2d().direct_space_state
	var from_pos = global_position - direction * 15.0
	var to_pos = global_position + direction * 15.0
	var query = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	query.exclude = [self.get_rid()]
	query.collision_mask = 1 # Collide with world geometry (layer 1)
	
	var result = space_state.intersect_ray(query)
	_apply_bounce_result(result)

func _apply_bounce_result(result: Dictionary) -> void:
	if result.is_empty():
		_fallback_bounce()
		return
	_reflect_direction(result.normal)

func _fallback_bounce() -> void:
	direction = -direction
	rotation = direction.angle()
	bounces_left -= 1

func _reflect_direction(normal: Vector2) -> void:
	direction = direction.bounce(normal)
	rotation = direction.angle()
	bounces_left -= 1
