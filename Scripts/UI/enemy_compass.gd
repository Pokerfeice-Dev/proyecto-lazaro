extends Node2D
class_name EnemyCompass

# Brújula / Indicador direccional en el borde de pantalla para los últimos
# 1 o 2 enemigos vivos de la sala cuando se encuentran fuera de pantalla.

const EDGE_MARGIN: float = 42.0
const OFFSCREEN_MARGIN: float = 40.0
const MAX_TRACKED_ENEMIES: int = 2

var arrows: Array[CompassArrow] = []

func _ready() -> void:
	z_index = 4095
	_create_arrows()

func _create_arrows() -> void:
	for i in range(MAX_TRACKED_ENEMIES):
		_add_arrow_instance()

func _add_arrow_instance() -> void:
	var arrow = CompassArrow.new()
	arrows.append(arrow)
	add_child(arrow)

func _process(delta: float) -> void:
	_update_compass(delta)

func _update_compass(delta: float) -> void:
	if not _is_room_eligible():
		_hide_all_arrows(delta)
		return

	var alive_enemies = _get_alive_enemies()
	if alive_enemies.is_empty():
		_hide_all_arrows(delta)
		return
	if alive_enemies.size() > MAX_TRACKED_ENEMIES:
		_hide_all_arrows(delta)
		return

	_update_arrow_tracking(alive_enemies, delta)

func _is_room_eligible() -> bool:
	var room = get_tree().get_first_node_in_group("combat_room")
	if not room:
		return true
	if room.get("room_cleared") == true:
		return false
	var start_area = room.get_node_or_null("Area_entered")
	if start_area and not room.get("room_started"):
		return false
	var spawned_so_far = room.get("enemies_spawned_so_far")
	var total_to_spawn = room.get("total_enemies_to_spawn")
	if start_area and spawned_so_far != null and total_to_spawn != null and spawned_so_far < total_to_spawn:
		return false
	return true

func _get_alive_enemies() -> Array[Node2D]:
	var result: Array[Node2D] = []
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		_collect_enemy_if_valid(enemy, result)
	return result

func _collect_enemy_if_valid(enemy: Node, result: Array[Node2D]) -> void:
	if not (enemy is Node2D): return
	if not _is_enemy_valid_target(enemy): return
	result.append(enemy as Node2D)

func _is_enemy_valid_target(enemy: Node) -> bool:
	if not is_instance_valid(enemy): return false
	if not enemy.is_inside_tree(): return false
	if enemy is Mannequin: return false
	if enemy.get("is_dying") == true: return false
	if enemy.get("is_spawning") == true: return false
	var hp = enemy.get("current_health")
	if hp != null and hp <= 0: return false
	return true

func _update_arrow_tracking(alive_enemies: Array[Node2D], delta: float) -> void:
	var viewport_size = get_viewport_rect().size
	_update_arrow_slot(0, alive_enemies, viewport_size, delta)
	_update_arrow_slot(1, alive_enemies, viewport_size, delta)

func _update_arrow_slot(slot: int, enemies: Array[Node2D], viewport_size: Vector2, delta: float) -> void:
	if slot >= arrows.size(): return
	var arrow = arrows[slot]
	if slot >= enemies.size():
		arrow.fade_out(delta)
		return
	var enemy = enemies[slot]
	_track_enemy_with_arrow(arrow, enemy, viewport_size, delta)

func _track_enemy_with_arrow(arrow: CompassArrow, enemy: Node2D, viewport_size: Vector2, delta: float) -> void:
	var screen_pos = enemy.get_global_transform_with_canvas().origin
	if not _is_pos_offscreen(screen_pos, viewport_size):
		arrow.fade_out(delta)
		return
	var center = viewport_size / 2.0
	var dir = (screen_pos - center).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	var target_pos = _calculate_edge_position(dir, viewport_size)
	arrow.update_pointer(target_pos, dir.angle(), delta)

func _is_pos_offscreen(pos: Vector2, viewport_size: Vector2) -> bool:
	var rect = Rect2(Vector2.ZERO, viewport_size).grow(-OFFSCREEN_MARGIN)
	return not rect.has_point(pos)

func _calculate_edge_position(dir: Vector2, viewport_size: Vector2) -> Vector2:
	var center = viewport_size / 2.0
	var half_extents = center - Vector2(EDGE_MARGIN, EDGE_MARGIN)
	var t_x = half_extents.x / absf(dir.x) if dir.x != 0.0 else INF
	var t_y = half_extents.y / absf(dir.y) if dir.y != 0.0 else INF
	return center + dir * minf(t_x, t_y)

func _hide_all_arrows(delta: float) -> void:
	for arrow in arrows:
		arrow.fade_out(delta)

# Flecha indicadora individual con dibujo vectorial y animación suave
class CompassArrow extends Node2D:
	var current_alpha: float = 0.0
	var target_alpha: float = 0.0

	func _ready() -> void:
		visible = false
		modulate.a = 0.0

	func _draw() -> void:
		_draw_shadow()
		_draw_body()
		_draw_pip()

	func _draw_shadow() -> void:
		var shadow_points = PackedVector2Array([
			Vector2(20, 0),
			Vector2(-12, -12),
			Vector2(-6, 0),
			Vector2(-12, 12)
		])
		draw_colored_polygon(shadow_points, Color(0.06, 0.06, 0.09, 0.85))

	func _draw_body() -> void:
		var body_points = PackedVector2Array([
			Vector2(16, 0),
			Vector2(-9, -9),
			Vector2(-4, 0),
			Vector2(-9, 9)
		])
		draw_colored_polygon(body_points, Color(1.0, 0.42, 0.16, 0.95))

	func _draw_pip() -> void:
		draw_circle(Vector2(-15, 0), 2.5, Color(1.0, 0.68, 0.25, 0.9))

	func update_pointer(target_pos: Vector2, target_rot: float, delta: float) -> void:
		target_alpha = 1.0
		current_alpha = move_toward(current_alpha, target_alpha, delta * 4.0)
		_apply_pulse_and_visibility()
		_apply_motion(target_pos, target_rot, delta)

	func fade_out(delta: float) -> void:
		target_alpha = 0.0
		current_alpha = move_toward(current_alpha, 0.0, delta * 5.0)
		_apply_pulse_and_visibility()

	func _apply_pulse_and_visibility() -> void:
		if current_alpha <= 0.001:
			visible = false
			modulate.a = 0.0
			return
		visible = true
		var pulse = 0.82 + 0.18 * sin(Time.get_ticks_msec() * 0.006)
		modulate.a = current_alpha * pulse

	func _apply_motion(target_pos: Vector2, target_rot: float, delta: float) -> void:
		if position == Vector2.ZERO:
			position = target_pos
			rotation = target_rot
			return
		position = position.lerp(target_pos, clampf(delta * 16.0, 0.0, 1.0))
		rotation = lerp_angle(rotation, target_rot, clampf(delta * 16.0, 0.0, 1.0))
