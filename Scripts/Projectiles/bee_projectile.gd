extends Projectile
class_name BeeProjectile

enum BeeState {
	SEARCH,
	HUNT
}

var current_state: BeeState = BeeState.SEARCH
var bee_index: int = 0
var total_bees: int = 3
var base_direction: Vector2 = Vector2.RIGHT
var target_node: Node2D = null
var has_target: bool = false
var elapsed_time: float = 0.0
var wave_frequency: float = 8.5
var wave_amplitude: float = 38.0
var phase_offset: float = 0.0
var micro_flutter_freq: float = 24.0
var scan_interval: float = 0.08
var time_since_last_scan: float = 0.0
var hunt_speed_multiplier: float = 1.25
var base_turn_speed: float = 8.0
var max_turn_speed: float = 15.0
var detection_radius: float = 420.0
var bee_shadow: DropShadow = null

@onready var anim_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func setup_bee_swarm(index: int, total: int, initial_dir: Vector2) -> void:
	bee_index = index
	total_bees = max(1, total)
	base_direction = initial_dir.normalized()
	direction = base_direction
	_configure_wave_parameters()

func _configure_wave_parameters() -> void:
	phase_offset = float(bee_index) * (PI * 0.72)
	wave_frequency = 8.0 + float(bee_index) * 1.3
	wave_amplitude = 36.0 + float(bee_index % 2) * 8.0

func set_homing_target(target: Node2D) -> void:
	if not _is_target_valid(target): return
	target_node = target
	has_target = true
	current_state = BeeState.HUNT
	_on_hunt_started()

func _ready() -> void:
	super._ready()
	_setup_bee_shadow()
	_setup_golden_trail()
	_init_sprite_animation()

func _setup_bee_shadow() -> void:
	bee_shadow = DropShadow.new()
	bee_shadow.top_level = true
	bee_shadow.shadow_size = Vector2(14.0, 7.0)
	bee_shadow.shadow_alpha = 0.35
	add_child(bee_shadow)
	_update_shadow_position()

func _update_shadow_position() -> void:
	if not bee_shadow: return
	bee_shadow.global_position = global_position + Vector2(0.0, 10.0)

func _setup_golden_trail() -> void:
	if not trail_particles: return
	trail_particles.amount = 14
	trail_particles.initial_velocity_min = 1.0
	trail_particles.initial_velocity_max = 5.0
	trail_particles.lifetime = 0.3
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 0.9, 0.3, 0.75))
	grad.add_point(0.4, Color(1.0, 0.75, 0.15, 0.45))
	grad.set_color(1, Color(0.8, 0.5, 0.1, 0.0))
	trail_particles.color_ramp = grad

func _init_sprite_animation() -> void:
	if not anim_sprite: return
	anim_sprite.speed_scale = 1.0

func _physics_process(delta: float) -> void:
	if is_destroyed: return
	elapsed_time += delta
	_update_bee_state(delta)
	_process_motion(delta)
	_update_shadow_position()
	_update_visuals()

func _update_bee_state(delta: float) -> void:
	if current_state == BeeState.SEARCH:
		_update_search_state(delta)
		return
	_update_hunt_state(delta)

func _update_search_state(delta: float) -> void:
	time_since_last_scan += delta
	if time_since_last_scan < scan_interval: return
	time_since_last_scan = 0.0
	_scan_and_acquire_enemy()

func _scan_and_acquire_enemy() -> void:
	if not get_tree(): return
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty(): return
	var candidates: Array = _filter_valid_enemies(enemies)
	if candidates.is_empty(): return
	var chosen: Node2D = _pick_best_candidate(candidates)
	if not chosen: return
	set_homing_target(chosen)

func _filter_valid_enemies(enemies: Array) -> Array:
	var valid: Array = []
	for enemy in enemies:
		if not _is_candidate_suitable(enemy): continue
		valid.append(enemy)
	return valid

func _is_candidate_suitable(enemy: Node) -> bool:
	var node_2d = enemy as Node2D
	if not node_2d: return false
	if not _is_target_valid(node_2d): return false
	var dist = global_position.distance_to(node_2d.global_position)
	if dist > detection_radius: return false
	if not _has_line_of_sight(global_position, node_2d.global_position): return false
	return true

func _pick_best_candidate(candidates: Array) -> Node2D:
	if candidates.size() == 1:
		return candidates[0] as Node2D
	return _pick_candidate_by_preference(candidates)

func _pick_candidate_by_preference(candidates: Array) -> Node2D:
	var best_candidate: Node2D = null
	var best_score: float = -INF
	for cand in candidates:
		var node_2d = cand as Node2D
		if not node_2d: continue
		var score = _calculate_candidate_score(node_2d)
		if score > best_score:
			best_score = score
			best_candidate = node_2d
	return best_candidate

func _calculate_candidate_score(candidate: Node2D) -> float:
	var to_cand = candidate.global_position - global_position
	var dist = to_cand.length()
	var dist_score = 1.0 - clampf(dist / detection_radius, 0.0, 1.0)
	var angle_diff = base_direction.angle_to(to_cand.normalized())
	var sector_match = _get_sector_affinity(angle_diff)
	return (dist_score * 0.6) + (sector_match * 0.4)

func _get_sector_affinity(angle_diff: float) -> float:
	if bee_index == 0:
		return 1.0 if angle_diff < -0.1 else 0.4
	if bee_index == 2:
		return 1.0 if angle_diff > 0.1 else 0.4
	return 1.0 if absf(angle_diff) <= 0.25 else 0.5

func _update_hunt_state(delta: float) -> void:
	if not _is_target_valid(target_node):
		_handle_lost_target()
		return
	_steer_towards_target(delta)

func _handle_lost_target() -> void:
	target_node = null
	has_target = false
	current_state = BeeState.SEARCH
	_on_hunt_ended()
	_scan_and_acquire_enemy()

func _steer_towards_target(delta: float) -> void:
	var head_pos = _get_bee_head_pos()
	var to_target = target_node.global_position - head_pos
	var dist = to_target.length()
	var target_dir = to_target.normalized()
	var adaptive_turn = lerpf(max_turn_speed, base_turn_speed, clampf(dist / detection_radius, 0.0, 1.0))
	var angle_to_target = direction.angle_to(target_dir)
	direction = direction.rotated(clampf(angle_to_target, -adaptive_turn * delta, adaptive_turn * delta))

func _get_bee_head_pos() -> Vector2:
	var head_node = get_node_or_null("Bee_head")
	if head_node:
		return head_node.global_position
	return global_position

func _process_motion(delta: float) -> void:
	if current_state == BeeState.SEARCH:
		_process_search_motion(delta)
		return
	_process_hunt_motion(delta)

func _process_search_motion(delta: float) -> void:
	var perp = Vector2(-base_direction.y, base_direction.x)
	var wave_phase = elapsed_time * wave_frequency + phase_offset
	var lateral_factor = cos(wave_phase) * (wave_amplitude * wave_frequency * 0.12)
	var flutter_phase = elapsed_time * micro_flutter_freq + (phase_offset * 2.0)
	var micro_flutter = sin(flutter_phase) * 14.0
	var search_velocity = (base_direction * speed) + (perp * (lateral_factor + micro_flutter))
	global_position += search_velocity * delta
	direction = search_velocity.normalized()
	rotation = direction.angle()

func _process_hunt_motion(delta: float) -> void:
	var current_speed = speed * hunt_speed_multiplier
	var perp = Vector2(-direction.y, direction.x)
	var wobble = perp * sin(elapsed_time * 16.0 + phase_offset) * 10.0
	var hunt_velocity = (direction * current_speed) + wobble
	global_position += hunt_velocity * delta
	rotation = direction.angle()

func _update_visuals() -> void:
	if not anim_sprite: return
	anim_sprite.flip_v = absf(rotation) > (PI * 0.5)

func _on_hunt_started() -> void:
	if anim_sprite:
		anim_sprite.speed_scale = 1.6
	_pulse_light(0.55)

func _on_hunt_ended() -> void:
	if anim_sprite:
		anim_sprite.speed_scale = 1.0
	_pulse_light(0.3)

func _pulse_light(energy_val: float) -> void:
	var light = get_node_or_null("PointLight2D") as PointLight2D
	if not light: return
	light.energy = energy_val

func _is_target_valid(target: Node2D) -> bool:
	if not target: return false
	if not is_instance_valid(target): return false
	if target.is_queued_for_deletion(): return false
	if "is_dying" in target and target.is_dying: return false
	if "current_health" in target and target.current_health <= 0: return false
	return true

func _has_line_of_sight(from_pos: Vector2, to_pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	if not space_state: return true
	var query = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	query.collision_mask = 1
	query.exclude = [self.get_rid()]
	var result = space_state.intersect_ray(query)
	return result.is_empty()

func _process_body_hit(body: Node2D) -> void:
	_spawn_sting_particles(global_position)
	super._process_body_hit(body)

func _spawn_sting_particles(hit_pos: Vector2) -> void:
	if not get_tree() or not get_tree().current_scene: return
	var sparks = CPUParticles2D.new()
	sparks.amount = 7
	sparks.lifetime = 0.22
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.z_index = 60
	sparks.z_as_relative = false
	sparks.direction = -direction
	sparks.spread = 60.0
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = 60.0
	sparks.initial_velocity_max = 120.0
	sparks.scale_amount_min = 1.5
	sparks.scale_amount_max = 2.8
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 0.95, 0.4, 1.0))
	grad.add_point(0.5, Color(1.0, 0.7, 0.1, 0.8))
	grad.set_color(1, Color(0.8, 0.4, 0.0, 0.0))
	sparks.color_ramp = grad
	var mat = CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sparks.material = mat
	get_tree().current_scene.add_child(sparks)
	sparks.global_position = hit_pos
	sparks.emitting = true
	sparks.finished.connect(sparks.queue_free)
