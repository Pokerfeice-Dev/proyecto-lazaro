extends CharacterBody2D
class_name EnemyBase

@export var max_health: int = 40
@export var current_health: int = 40
@export var move_speed: float = 150.0
@export var damage: int = 10
@export var attack_speed: float = 1.0

@export var flesh_scene: PackedScene = preload("res://Scenes/UI/flesh.tscn")
@export var flesh_drop_chance: float = 1.0
@export var item_drop_scene: PackedScene = preload("res://Scenes/Items/item_drop_world.tscn")
@export var all_items: Array[ItemData] = [
	preload("res://Art/Items/Weapons/Item1.tres"),
	preload("res://Art/Items/Weapons/Item2.tres"),
	preload("res://Art/Items/Weapons/Item3.tres"),
	preload("res://Art/Items/Weapons/Item4.tres"),
	preload("res://Art/Items/Weapons/Item5.tres"),
	preload("res://Art/Items/Weapons/Item6.tres"),
	preload("res://Art/Items/Weapons/Item7_Colmena.tres"),
	preload("res://Art/Items/Weapons/Item8_CabezaHumana.tres"),
	preload("res://Art/Items/Weapons/Item9_SierraCircular.tres"),
	preload("res://Art/Items/Weapons/Item10_Bateria.tres"),
	preload("res://Art/Items/Weapons/Item11_Gasolina.tres"),
	preload("res://Art/Items/Weapons/Item12_Nitrogeno.tres"),
	preload("res://Art/Items/Player/Body/Item2_TorsoBlindado.tres"),
	preload("res://Art/Items/Player/Body/Item3_TorsoEspinado.tres"),
	preload("res://Art/Items/Player/Body/Item4_TorsoLigero.tres"),
	preload("res://Art/Items/Player/Legs/Item2_PiernasRodantes.tres"),
	preload("res://Art/Items/Player/Legs/Item3_PiernasCaninas.tres"),
	preload("res://Art/Items/Player/Legs/Item4_PiernasBionicas.tres"),
	preload("res://Art/Items/Player/Arms/Item2_BrazoReforzado.tres"),
	preload("res://Art/Items/Player/Arms/Item3_BrazoLigero.tres"),
	preload("res://Art/Items/Player/Arms/Item4_BrazoArmado.tres")
]
@export var item_drop_chance: float = 0.05

var target: Node2D = null
var is_spawning: bool = false
var is_dying: bool = false
@export var use_legacy_death_fx := false
const PIXEL_DEATH = preload("res://Scripts/Effects/pixel_death.gd")
var knockback_velocity: Vector2 = Vector2.ZERO
var hit_stun_timer: float = 0.0

@export var detection_radius: float = 280.0
var has_detected_player: bool = false
var is_stuck: bool = false
var _stuck_timer: float = 0.0
var _last_stuck_pos: Vector2 = Vector2.ZERO
var _current_nav_path: PackedVector2Array = PackedVector2Array()
var _nav_recalc_timer: float = 0.0
var _nav_target_last_pos: Vector2 = Vector2.ZERO
var _avoidance_angle_bias: float = 1.0
var _avoidance_bias_timer: float = 0.0
const EnemyCrowd = preload("res://Scripts/World/enemy_crowd.gd")
var _crowd_offset := Vector2.ZERO

const EnemyNavigation = preload("res://Scripts/World/enemy_navigation.gd")
var _nav_clearance := 0.0
var _nav_probe: PhysicsShapeQueryParameters2D
var _nav_probe_refresh := 0

var is_elite: bool = false
signal enemy_died(enemy: EnemyBase)

var _default_modulate: Color = Color.WHITE
var _flash_tween: Tween = null
var drop_shadow: DropShadow = null

var has_footstep_fx: bool = true
var is_heavy_stepper: bool = false
var _enemy_footstep_timer: float = 0.0
var _enemy_footstep_interval: float = 0.38
var _enemy_footstep_side: int = 1

var base_move_speed: float = -1.0
var _speed_modifiers: Dictionary = {}

func set_speed_modifier(source_id: String, multiplier: float) -> void:
	if base_move_speed < 0.0:
		base_move_speed = move_speed
	_speed_modifiers[source_id] = multiplier
	_recalculate_move_speed()
	_update_slow_visuals()

func remove_speed_modifier(source_id: String) -> void:
	_speed_modifiers.erase(source_id)
	_recalculate_move_speed()
	_update_slow_visuals()

func _recalculate_move_speed() -> void:
	if base_move_speed < 0.0: return
	var mult = 1.0
	for m in _speed_modifiers.values():
		mult *= m
	move_speed = base_move_speed * mult

func _update_slow_visuals() -> void:
	var spr = _get_sprite()
	if not spr: return
	if _speed_modifiers.has("ice_puddle") or _speed_modifiers.has("nitrogen_slow"):
		spr.modulate = Color(0.65, 0.85, 1.3, 1.0)
		return
	spr.modulate = _default_modulate

func _ready() -> void:
	base_move_speed = move_speed
	z_index = 5
	_last_stuck_pos = global_position
	current_health = max_health
	add_to_group("enemy")
	# Bodies keep the enemy layer for weapon hits; movement uses soft avoidance.
	set_collision_mask_value(2, false)
	set_collision_mask_value(5, true) # vacíos de la zona 3 (ver combat_room.gd)
	_find_player()
	
	var sprite = _get_sprite()
	if sprite:
		_default_modulate = sprite.modulate
		_default_modulate.a = 1.0
		
	if is_elite:
		max_health = int(max_health * 1.5)
		current_health = max_health
		damage = int(damage * 1.25)
		scale = Vector2(1.25, 1.25)
		modulate = Color(1.3, 0.8, 0.8)
	_setup_health_bar()
	_setup_enemy_shadow()



func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		# Enemigos pre-colocados en la sala (ej. bosses) hacen _ready() antes de que
		# el jugador termine de instanciarse (se agrega con call_deferred). Reintenta
		# en el próximo idle frame hasta que exista, en vez de quedarse sin target.
		if is_inside_tree():
			get_tree().create_timer(0.1).timeout.connect(_find_player, CONNECT_ONE_SHOT)
		return
	target = players[0]
	add_collision_exception_with(target)

func _setup_health_bar() -> void:
	var bar = ProgressBar.new()
	bar.max_value = max_health
	bar.value = current_health
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(30, 4)
	bar.position = Vector2(-15, -30)
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	sb_bg.corner_radius_top_left = 2
	sb_bg.corner_radius_top_right = 2
	sb_bg.corner_radius_bottom_left = 2
	sb_bg.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("background", sb_bg)
	
	var sb_fill = StyleBoxFlat.new()
	sb_fill.bg_color = Color(0.8, 0.1, 0.1, 0.9)
	sb_fill.corner_radius_top_left = 2
	sb_fill.corner_radius_top_right = 2
	sb_fill.corner_radius_bottom_left = 2
	sb_fill.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("fill", sb_fill)
	
	bar.name = "HealthBar"
	add_child(bar)

func _setup_enemy_shadow() -> void:
	var existing = get_node_or_null("DropShadow") as DropShadow
	if existing:
		drop_shadow = existing
		if is_elite:
			drop_shadow.shadow_size *= 1.25
		return
	var shadow_dim = _get_enemy_shadow_dimensions()
	var final_size: Vector2 = shadow_dim.size
	var final_offset: Vector2 = shadow_dim.offset
	if is_elite:
		final_size *= 1.25
	drop_shadow = DropShadow.attach_to(self, final_size, final_offset, 0.4)


func _get_enemy_shadow_dimensions() -> Dictionary:
	var script_path = get_script().resource_path.to_lower()
	if "tank" in script_path or "mecha" in script_path:
		return {"size": Vector2(44.0, 18.0), "offset": Vector2(0.0, 16.0)}
	if "boss2" in script_path:
		return {"size": Vector2(76.0, 32.0), "offset": Vector2(0.0, 28.0)}
	if "boss" in script_path:
		return {"size": Vector2(64.0, 28.0), "offset": Vector2(0.0, 26.0)}
	if "bee_summon" in script_path:
		return {"size": Vector2(18.0, 9.0), "offset": Vector2(0.0, 14.0)}
	if "turret" in script_path or "delivery" in script_path:
		return {"size": Vector2(32.0, 14.0), "offset": Vector2(0.0, 12.0)}
	return {"size": Vector2(26.0, 12.0), "offset": Vector2(0.0, 14.0)}

func spawn_appear() -> void:
	is_spawning = true
	set_physics_process(false)
	_hide_sprite_alpha()
	_hide_shadow_alpha()
	_play_summon_anim()

func _hide_shadow_alpha() -> void:
	if not drop_shadow: return
	drop_shadow.modulate.a = 0.0

func _fade_in_shadow() -> void:
	if not drop_shadow: return
	drop_shadow.fade_in(0.2)

func _hide_sprite_alpha() -> void:
	var sprite = _get_sprite()
	if not sprite: return
	sprite.modulate.a = 0.0

func _get_sprite() -> Node2D:
	var sprite = get_node_or_null("AnimatedSprite2D")
	if not sprite: sprite = get_node_or_null("Sprite2D")
	return sprite

func _play_summon_anim() -> void:
	var summon_anim = get_node_or_null("Summon_anim")
	if not summon_anim:
		_fade_in_sprite()
		return
	summon_anim.show()
	_safe_play_animated_sprite(summon_anim, "summon")
	summon_anim.animation_finished.connect(_on_summon_finished.bind(summon_anim), CONNECT_ONE_SHOT)

func _on_summon_finished(summon_anim: Node) -> void:
	summon_anim.hide()
	_fade_in_sprite()

func _fade_in_sprite() -> void:
	var sprite = _get_sprite()
	if not sprite:
		_finish_spawn()
		return
	_fade_in_shadow()
	var t = create_tween()
	t.tween_property(sprite, "modulate:a", 1.0, 0.2)
	t.finished.connect(_finish_spawn, CONNECT_ONE_SHOT)

func _finish_spawn() -> void:
	set_physics_process(true)
	is_spawning = false

func _physics_process(delta: float) -> void:
	if hit_stun_timer > 0.0:
		hit_stun_timer -= delta
	else:
		_check_detection_range()
		process_movement(delta)
	
	_apply_crowd_avoidance(delta)
	_update_stuck_detection(delta)
	_process_knockback(delta)
	move_and_slide()
	handle_collisions()
	_update_footstep_fx(delta)

func _update_footstep_fx(delta: float) -> void:
	if not has_footstep_fx: return
	if is_dying or is_spawning: return
	if velocity.length() < 25.0: return
	
	_enemy_footstep_timer -= delta
	if _enemy_footstep_timer > 0.0: return
	
	_trigger_enemy_footstep()

const FootstepFXScript = preload("res://Scripts/Effects/footstep_fx.gd")

func _trigger_enemy_footstep() -> void:
	_enemy_footstep_timer = _enemy_footstep_interval
	_enemy_footstep_side = -_enemy_footstep_side
	var move_dir = velocity.normalized()
	var foot_pos = global_position + _get_footstep_offset()
	var heavy = is_heavy_stepper or is_elite
	FootstepFXScript.spawn_footstep(get_tree(), foot_pos, move_dir, heavy, _enemy_footstep_side)

func _get_footstep_offset() -> Vector2:
	return Vector2(0, 8)

func _process_knockback(delta: float) -> void:
	if knockback_velocity.length() > 5.0:
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 10.0 * delta)
		velocity += knockback_velocity
		return
	knockback_velocity = Vector2.ZERO

func apply_knockback(force: float, direction: Vector2) -> void:
	if is_dying: return
	knockback_velocity = direction.normalized() * force

func process_movement(_delta: float) -> void:
	pass # To be overridden by specific enemy types

func take_damage(amount: int, is_crit: bool = false) -> void:
	if is_dying: return
	current_health -= amount
	hit_stun_timer = 0.15
	alert_to_player()
	_show_damage_text(amount, is_crit)
	_flash_hit()
	Sfx.play_at(Sfx.HIT, global_position, -4.0 if not is_crit else 0.0)
	_update_health_bar()
	_check_death()

# --- Detección y Alerta ---

func _check_detection_range() -> void:
	if has_detected_player: return
	if not target or not is_instance_valid(target):
		_find_player()
		return
	if global_position.distance_to(target.global_position) <= detection_radius:
		alert_to_player()

func alert_to_player() -> void:
	has_detected_player = true
	if not target or not is_instance_valid(target):
		_find_player()
	_on_player_alerted()

func _on_player_alerted() -> void:
	pass

# --- Detección de Obstáculos (Línea de Visión) ---

func has_line_of_sight_to_player() -> bool:
	if not target or not is_instance_valid(target):
		return false
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, target.global_position)
	query.exclude = [self.get_rid(), target.get_rid()]
	query.collision_mask = EnemyNavigation.OBSTACLE_MASK
	var result = space_state.intersect_ray(query)
	return result.is_empty()

# --- Detección de Atascamiento ---

func _update_stuck_detection(delta: float) -> void:
	if not has_detected_player or velocity.length() < 20.0:
		_reset_stuck_state()
		return
	
	var dist_moved = global_position.distance_to(_last_stuck_pos)
	_evaluate_stuck_movement(dist_moved, delta)
	_last_stuck_pos = global_position

func _reset_stuck_state() -> void:
	_stuck_timer = 0.0
	is_stuck = false
	_last_stuck_pos = global_position

func _evaluate_stuck_movement(dist_moved: float, delta: float) -> void:
	if dist_moved < (move_speed * 0.15 * delta):
		_stuck_timer += delta
		if _stuck_timer >= 0.25:
			is_stuck = true
		return
	_stuck_timer = maxf(0.0, _stuck_timer - delta * 2.0)
	if _stuck_timer == 0.0:
		is_stuck = false

# --- Navegación y Pathfinding ---

func get_nav_direction_to_target() -> Vector2:
	if not target or not is_instance_valid(target):
		return Vector2.ZERO
	
	var has_los = _can_walk_segment(global_position, target.global_position)
	if has_los and not is_stuck:
		_clear_nav_path()
		return (target.global_position - global_position).normalized()
	if not _can_walk_segment(global_position, global_position):
		return _escape_obstacle_margin()
		
	return _get_pathing_direction()

func _get_pathing_direction() -> Vector2:
	_update_nav_path_if_needed()
	if _has_valid_waypoints():
		return _get_direction_from_waypoints()
	return _get_feeler_avoidance_direction()

func _update_nav_path_if_needed() -> void:
	_nav_recalc_timer -= get_physics_process_delta_time()
	var target_moved = target.global_position.distance_to(_nav_target_last_pos) > 64.0
	if _nav_recalc_timer > 0.0 and not target_moved:
		return
	_recalculate_nav_path()

func _recalculate_nav_path() -> void:
	_nav_recalc_timer = 0.35 + float(get_instance_id() % 11) * 0.013
	_nav_target_last_pos = target.global_position
	var room = _get_current_combat_room()
	if not room:
		_current_nav_path.clear()
		return
	_current_nav_path = room.get_nav_path(global_position, target.global_position, _get_nav_clearance())
	_trim_reached_waypoints()

func _get_current_combat_room() -> Node:
	var node: Node = get_parent()
	while node:
		if node.has_method("get_nav_path"):
			return node
		node = node.get_parent()
	return get_tree().get_first_node_in_group("combat_room")

func _has_valid_waypoints() -> bool:
	return not _current_nav_path.is_empty()

func _get_direction_from_waypoints() -> Vector2:
	_trim_reached_waypoints()
	if _current_nav_path.is_empty():
		return _get_feeler_avoidance_direction()
	# Solo se acorta la ruta cuando cabe el cuerpo entero, sin cortar esquinas.
	for i in range(mini(_current_nav_path.size() - 1, 6), 0, -1):
		if _can_walk_segment(global_position, _current_nav_path[i]):
			for skipped in i: _current_nav_path.remove_at(0)
			break
	var next_point = _current_nav_path[0]
	if not _can_walk_segment(global_position, next_point):
		return _get_feeler_avoidance_direction()
	var offset: Vector2 = next_point - global_position
	return offset.normalized() * minf(1.0, offset.length() / maxf(move_speed * get_physics_process_delta_time(), 0.01))

func _trim_reached_waypoints() -> void:
	while not _current_nav_path.is_empty():
		var next_wp = _current_nav_path[0]
		if global_position.distance_to(next_wp) > maxf(2.0, move_speed * get_physics_process_delta_time()):
			break
		if _current_nav_path.size() > 1 and not _can_walk_segment(global_position, _current_nav_path[1]):
			break
		_current_nav_path.remove_at(0)

func _clear_nav_path() -> void:
	_current_nav_path.clear()
	_nav_recalc_timer = 0.0

func _get_nav_clearance() -> float:
	if _nav_clearance > 0.0: return _nav_clearance
	_nav_clearance = 6.0
	for child in get_children():
		if child is CollisionShape2D and child.shape and not child.disabled:
			var rect: Rect2 = child.shape.get_rect()
			var extent: Vector2 = rect.size * 0.5 * child.global_scale.abs()
			var radius := extent.length() if child.shape is RectangleShape2D else maxf(extent.x, extent.y)
			_nav_clearance = maxf(_nav_clearance, radius + global_position.distance_to(child.global_position) + 1.5)
	return _nav_clearance

func _can_walk_segment(start: Vector2, finish: Vector2) -> bool:
	var now := Time.get_ticks_msec()
	if not _nav_probe or now >= _nav_probe_refresh:
		_nav_probe = EnemyNavigation.query_for(_get_nav_clearance(), EnemyNavigation.actor_exclusions(get_tree()))
		_nav_probe_refresh = now + 400
	return EnemyNavigation.clear_segment(get_world_2d().direct_space_state, _nav_probe, start, finish)

func _escape_obstacle_margin() -> Vector2:
	# Una colisión con otro enemigo puede empujarnos dentro del margen de seguridad.
	# Salimos con el cuerpo físico antes de volver a pedir una ruta con margen.
	var desired := (target.global_position - global_position).normalized()
	var best := Vector2.ZERO
	var best_score := -INF
	for i in 16:
		var direction := Vector2.from_angle(float(i) * TAU / 16)
		var motion := direction * maxf(12, _get_nav_clearance())
		if test_move(global_transform, motion): continue
		if not _can_walk_segment(global_position + motion, global_position + motion): continue
		var score := desired.dot(direction) + velocity.normalized().dot(direction) * 0.3
		if score > best_score:
			best_score = score
			best = direction
	_nav_recalc_timer = 0.0
	return best

# --- Evasión Local con Ray Probes (Feeler Avoidance) ---

func _get_feeler_avoidance_direction() -> Vector2:
	var target_dir = (target.global_position - global_position).normalized()
	_update_avoidance_bias()
	
	var best_dir = Vector2.ZERO
	var best_score = -999.0
	var probe_angles = [0.0, 30.0, -30.0, 60.0, -60.0, 90.0, -90.0, 120.0, -120.0, 150.0, -150.0, 180.0]
	
	for angle_deg in probe_angles:
		var test_dir = target_dir.rotated(deg_to_rad(angle_deg * _avoidance_angle_bias))
		var score = _evaluate_direction_probe(test_dir, target_dir)
		if score > -9.0 and score > best_score:
			best_score = score
			best_dir = test_dir
			
	return best_dir

func _update_avoidance_bias() -> void:
	var dt = get_physics_process_delta_time()
	_avoidance_bias_timer -= dt
	if _avoidance_bias_timer <= 0.0 and is_stuck:
		_avoidance_angle_bias = -_avoidance_angle_bias
		_avoidance_bias_timer = 0.8

func _evaluate_direction_probe(dir: Vector2, target_dir: Vector2) -> float:
	var probe_dist = maxf(18.0, move_speed * 0.2)
	if not _can_walk_segment(global_position, global_position + dir * probe_dist):
		return -10.0
	return dir.dot(target_dir) + dir.dot(velocity.normalized()) * 0.25

func _update_health_bar() -> void:
	var bar = get_node_or_null("HealthBar")
	if not bar: return
	var t = create_tween()
	var target_val = maxi(0, current_health)
	t.tween_property(bar, "value", target_val, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _show_damage_text(amount: int, is_crit: bool) -> void:
	var label = Label.new()
	if is_crit:
		label.text = "¡%d!" % amount
		label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_outline_color", Color(0.8, 0.2, 0.0))
		label.add_theme_constant_override("outline_size", 4)
	else:
		label.text = str(amount)
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
		label.add_theme_constant_override("outline_size", 3)
	
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(100, 30)
	label.position = Vector2(-50, -15)
	
	var floating_node = Node2D.new()
	floating_node.global_position = global_position + Vector2(randf_range(-15.0, 15.0), -40.0)
	floating_node.add_child(label)
	
	get_tree().current_scene.call_deferred("add_child", floating_node)
	
	var dir_x = -1.0 if randf() < 0.5 else 1.0
	var random_x = dir_x * randf_range(15.0, 40.0)
	var random_y = randf_range(-45.0, -60.0)
	
	var tween = get_tree().create_tween().bind_node(floating_node).set_parallel(true)
	tween.tween_property(floating_node, "global_position", floating_node.global_position + Vector2(random_x, random_y), 0.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.chain().tween_callback(floating_node.queue_free)

const FREEZE_COLOR := Color(0.35, 0.85, 2.2, 1.0)
var is_frozen_by_ice: bool = false
var is_electrified: bool = false # tinte amarillo mientras dura el stun de Relampago
var _freeze_timer: Timer = null
var _frozen_paused_timers: Array[Timer] = []

func freeze_enemy(duration: float = 5.0) -> void:
	if is_dying: return
	is_frozen_by_ice = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process(false)
	_pause_enemy_for_freeze()
	_apply_freeze_visuals()
	_schedule_unfreeze(duration)

func _apply_freeze_visuals() -> void:
	var sprite = _get_sprite()
	if sprite:
		sprite.modulate = FREEZE_COLOR

func _pause_enemy_for_freeze() -> void:
	_pause_enemy_animations()
	_pause_enemy_internal_timers()

func _pause_enemy_animations() -> void:
	for anim_sprite in find_children("*", "AnimatedSprite2D", true, false):
		if anim_sprite is AnimatedSprite2D:
			anim_sprite.pause()
	for anim_player in find_children("*", "AnimationPlayer", true, false):
		if anim_player is AnimationPlayer:
			anim_player.pause()

func _pause_enemy_internal_timers() -> void:
	_frozen_paused_timers.clear()
	for child in find_children("*", "Timer", true, false):
		var t = child as Timer
		if t != _freeze_timer and not t.is_stopped() and t.paused == false:
			t.paused = true
			_frozen_paused_timers.append(t)

func _resume_enemy_animations() -> void:
	for anim_sprite in find_children("*", "AnimatedSprite2D", true, false):
		if anim_sprite is AnimatedSprite2D and not anim_sprite.is_playing():
			anim_sprite.play()
	for anim_player in find_children("*", "AnimationPlayer", true, false):
		if anim_player is AnimationPlayer and not anim_player.is_playing():
			anim_player.play()

func _resume_enemy_internal_timers() -> void:
	for t in _frozen_paused_timers:
		if is_instance_valid(t):
			t.paused = false
	_frozen_paused_timers.clear()

func _schedule_unfreeze(duration: float) -> void:
	if _freeze_timer and is_instance_valid(_freeze_timer):
		_freeze_timer.stop()
		_freeze_timer.queue_free()
	_freeze_timer = Timer.new()
	_freeze_timer.one_shot = true
	_freeze_timer.wait_time = duration
	_freeze_timer.timeout.connect(_on_freeze_timeout)
	add_child(_freeze_timer)
	_freeze_timer.start()

func _on_freeze_timeout() -> void:
	_unfreeze_enemy()

func _unfreeze_enemy() -> void:
	if _freeze_timer and is_instance_valid(_freeze_timer):
		_freeze_timer.queue_free()
		_freeze_timer = null
	if not is_instance_valid(self) or is_dying: return
	is_frozen_by_ice = false
	var sprite = _get_sprite()
	if sprite and is_instance_valid(sprite):
		sprite.modulate = _default_modulate
	_resume_enemy_animations()
	_resume_enemy_internal_timers()
	set_physics_process(true)
	set_process(true)
func apply_status_effect(effect_type: String) -> void:
	if is_dying:
		return
	match effect_type:
		"stun":
			_apply_stun_effect(1.0)
		"burn":
			_apply_burn_effect(3.0)
		"slow":
			_apply_slow_effect(3.0, 0.5)

func _apply_stun_effect(duration: float) -> void:
	hit_stun_timer = maxf(hit_stun_timer, duration)
	is_electrified = true
	var sprite = _get_sprite()
	if sprite:
		sprite.modulate = Color(0.2, 0.7, 2.5, 1.0) # Azul electrico
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(_on_stun_effect_timeout)

func _on_stun_effect_timeout() -> void:
	if not is_instance_valid(self) or is_dying:
		return
	is_electrified = false
	var sprite = _get_sprite()
	if sprite and is_instance_valid(sprite):
		sprite.modulate = _default_modulate
	_update_slow_visuals()

func _apply_burn_effect(duration: float) -> void:
	var tick_interval = 0.5
	var burn_dmg = maxi(1, int(float(damage) * 0.5))
	IgniteEffect.apply_ignite(self, burn_dmg, tick_interval, duration)

func _apply_slow_effect(duration: float, multiplier: float) -> void:
	set_speed_modifier("nitrogen_slow", multiplier)
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(_on_slow_effect_timeout)

func _on_slow_effect_timeout() -> void:
	if not is_instance_valid(self) or is_dying:
		return
	remove_speed_modifier("nitrogen_slow")

func _flash_hit() -> void:
	var sprite = _get_sprite()
	if not sprite:
		return
	_cancel_active_flash_tween()
	var target_col = _get_flash_target_color()
	sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
	_start_flash_tween(sprite, target_col)

func _cancel_active_flash_tween() -> void:
	if not _flash_tween:
		return
	if not _flash_tween.is_valid():
		return
	_flash_tween.kill()

func _get_flash_target_color() -> Color:
	if is_frozen_by_ice:
		return FREEZE_COLOR
	if is_electrified:
		return Color(0.2, 0.7, 2.5, 1.0)
	if _speed_modifiers.has("ice_puddle") or _speed_modifiers.has("nitrogen_slow"):
		return Color(0.65, 0.85, 1.3, 1.0)
	return _default_modulate

func _start_flash_tween(sprite: Node2D, target_col: Color) -> void:
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "modulate", target_col, 0.18)

func _flash_red() -> void:
	_flash_hit()

func _check_death() -> void:
	if current_health > 0: return
	die()

func die() -> void:
	if is_dying: return
	is_dying = true
	_disable_physics()
	GameData.run_enemies_killed += 1
	GameData.protocol_enemy_defeated(self)
	_unlock_bestiary_entry()
	enemy_died.emit(self)
	_attempt_drops()
	if not use_legacy_death_fx:
		_spawn_pixel_death()
	_hide_sprite()
	_hide_health_bar()
	_fade_shadow()
	_play_death_sound()
	if use_legacy_death_fx:
		_play_death_fx()
	else:
		var legacy_fx = get_node_or_null("Death_fx")
		if legacy_fx:
			legacy_fx.hide()
		# Mantiene vivo el jefe final hasta que termine su flujo de victoria.
		var delay := 1.1
		if "victory_delay" in self:
			delay = maxf(delay, get("victory_delay") + 0.5)
		get_tree().create_timer(delay, false).timeout.connect(_check_sound_and_free)

func _spawn_pixel_death() -> void:
	# La torreta tiene base y cañón separados; los demás exponen su cuerpo.
	if get_node_or_null("Sprite_BaseTurret") or get_node_or_null("Sprite_CannonTurret"):
		PIXEL_DEATH.spawn_from(get_node_or_null("Sprite_BaseTurret"))
		PIXEL_DEATH.spawn_from(get_node_or_null("Sprite_CannonTurret"))
	else:
		PIXEL_DEATH.spawn_from(_get_sprite())

func _fade_shadow() -> void:
	if not drop_shadow: return
	drop_shadow.fade_out(0.25)

func _unlock_bestiary_entry() -> void:
	if not is_inside_tree() or not GameData.has_method("unlock_codex_entry"): return
	var script_path = get_script().resource_path.to_lower()
	if "follower" in script_path:
		GameData.unlock_codex_entry("enemies", "follower")
	elif "shooter" in script_path or "carpenter" in script_path:
		GameData.unlock_codex_entry("enemies", "shooter")
	elif "tank" in script_path or "mecha" in script_path:
		GameData.unlock_codex_entry("enemies", "tank")
	elif "turret" in script_path or "delivery" in script_path:
		GameData.unlock_codex_entry("enemies", "turret")
	elif "bee_summon" in script_path:
		GameData.unlock_codex_entry("enemies", "charger")
	elif "summoner" in script_path:
		GameData.unlock_codex_entry("enemies", "spawner")
	elif "boss2" in script_path:
		GameData.unlock_codex_entry("enemies", "boss2")
	elif "boss" in script_path:
		GameData.unlock_codex_entry("enemies", "boss")

func _hide_health_bar() -> void:
	var bar = get_node_or_null("HealthBar")
	if not bar: return
	bar.hide()

func _attempt_drops() -> void:
	var scene_name = get_tree().current_scene.name.to_lower()
	if "training" in scene_name or "tutorial" in scene_name:
		return
		
	var is_boss = get_script().resource_path.to_lower().contains("boss")
	if is_boss:
		for k in range(10):
			var offset = Vector2(randf_range(-25, 25), randf_range(-25, 25))
			_spawn_flesh_at(global_position + offset)
		_spawn_item_at(global_position)
		return

	var spawns_flesh = _should_drop_flesh()
	var spawns_item = _should_drop_item()
	
	if is_elite:
		var extra_scrap = randi_range(15, 30)
		GameData.add_scrap(extra_scrap)
		
		if spawns_flesh:
			for k in range(3):
				var offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
				_spawn_flesh_at(global_position + offset)
		if spawns_item:
			_spawn_item_at(global_position)
		return

	if spawns_flesh and spawns_item:
		_spawn_flesh_at(global_position + Vector2(-20, 0))
		_spawn_item_at(global_position + Vector2(20, 0))
		return

	if spawns_flesh:
		_spawn_flesh_at(global_position)
		return

	if spawns_item:
		_spawn_item_at(global_position)
		return

func _should_drop_flesh() -> bool:
	if not flesh_scene: return false
	var bonus = GameData.core_upgrades.get("recuperacion_restos", 0) * 0.01
	return randf() <= (flesh_drop_chance + bonus)

func _should_drop_item() -> bool:
	if not item_drop_scene:
		print("ERROR: item_drop_scene no está asignado.")
		return false
	if all_items.is_empty():
		return false
	var chance = 0.1 if is_elite else item_drop_chance
	var bonus = GameData.core_upgrades.get("recuperacion_restos", 0) * 0.01
	return randf() <= (chance + bonus)

func _spawn_flesh_at(pos: Vector2) -> void:
	var flesh_inst = flesh_scene.instantiate()
	flesh_inst.global_position = pos
	get_tree().current_scene.call_deferred("add_child", flesh_inst)

func _spawn_item_at(pos: Vector2) -> void:
	var item_drop = item_drop_scene.instantiate()
	item_drop.item_data = all_items.pick_random()
	item_drop.global_position = pos
	get_tree().current_scene.call_deferred("add_child", item_drop)
	print("Item instanciado exitosamente.")

var _owned_attacks: Array[WeakRef] = []

func register_attack(attack: Node) -> void:
	_owned_attacks = _owned_attacks.filter(func(ref): return is_instance_valid(ref.get_ref()))
	_owned_attacks.append(weakref(attack))

func _disable_physics() -> void:
	set_physics_process(false)
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	_disable_attack_nodes(self)
	for ref in _owned_attacks:
		var attack = ref.get_ref()
		if not is_instance_valid(attack): continue
		attack.process_mode = Node.PROCESS_MODE_DISABLED
		_disable_attack_nodes(attack)
		if attack is CanvasItem: attack.hide()
		attack.queue_free()
	_owned_attacks.clear()

func _disable_attack_nodes(root: Node) -> void:
	if root is CollisionObject2D:
		root.collision_layer = 0
		root.collision_mask = 0
	if root is Area2D:
		root.set_deferred("monitoring", false)
		root.set_deferred("monitorable", false)
	if root is CollisionShape2D or root is CollisionPolygon2D:
		root.set_deferred("disabled", true)
	if root is Timer: root.stop()
	if root is AnimationPlayer or root is AnimatedSprite2D: root.stop()
	for child in root.get_children(): _disable_attack_nodes(child)

func _hide_sprite() -> void:
	var sprite = _get_sprite()
	if not sprite: return
	sprite.hide()

func _play_death_sound() -> void:
	var death_sound = get_node_or_null("Death_sound")
	if not death_sound: death_sound = get_node_or_null("DeathSound")
	if not death_sound: return
	if not death_sound.has_method("play"): return
	death_sound.bus = "SFX"
	death_sound.play()

func _play_death_fx() -> void:
	var death_fx = get_node_or_null("Death_fx")
	if not death_fx:
		_check_sound_and_free()
		return
	death_fx.show()
	_safe_play_animated_sprite(death_fx, "death")
	death_fx.animation_finished.connect(_on_death_fx_finished, CONNECT_ONE_SHOT)

func _on_death_fx_finished() -> void:
	queue_free()

func _check_sound_and_free() -> void:
	var ds = get_node_or_null("Death_sound")
	if not ds: ds = get_node_or_null("DeathSound")
	if ds and ds.playing:
		ds.finished.connect(queue_free, CONNECT_ONE_SHOT)
		return
	queue_free()

func handle_collisions() -> void:
	pass

func _safe_play_animated_sprite(sprite: AnimatedSprite2D, anim_name: String) -> void:
	if not sprite: return
	if not sprite.sprite_frames: return
	if not sprite.sprite_frames.has_animation(anim_name): return
	sprite.play(anim_name)

func _apply_crowd_avoidance(delta: float) -> void:
	var speed := velocity.length()
	# Preserve planted attacks, frozen actors, lunges and knockback trajectories.
	if is_dying or is_spawning or hit_stun_timer > 0.0 or speed < 5.0 or speed > move_speed * 1.5 or knockback_velocity.length() > 5.0:
		_crowd_offset = Vector2.ZERO
		return
	var forward := velocity / speed
	var right := forward.orthogonal()
	var correction := Vector2.ZERO
	var own_radius := clampf(_get_nav_clearance(), 8.0, 40.0)
	for sample in EnemyCrowd.neighbors(self):
		var other = sample.body
		if not is_instance_valid(other) or other.get("is_dying") == true: continue
		var offset: Vector2 = sample.position - global_position
		var distance := offset.length()
		var other_radius := 16.0
		if other.has_method("_get_nav_clearance"):
			other_radius = clampf(other._get_nav_clearance(), 8.0, 40.0)
		var spacing := own_radius + other_radius + 5.0
		if distance > spacing + speed * 0.3: continue
		var toward := offset / maxf(distance, 0.01)
		if distance < 0.01:
			toward = Vector2.RIGHT if get_instance_id() < other.get_instance_id() else Vector2.LEFT
		var overlap := clampf((spacing - distance) / spacing, 0.0, 1.0)
		correction -= toward * overlap * speed * 0.85
		var relative_velocity: Vector2 = velocity - sample.velocity
		var closing := relative_velocity.dot(toward)
		if forward.dot(toward) > 0.2 and closing > 0.0:
			var anticipation := clampf((spacing + closing * 0.3 - distance) / spacing, 0.0, 1.0)
			# Fixed right-hand preference avoids alternating left/right in head-on traffic.
			var side := -1.0 if offset.dot(right) > spacing * 0.25 else 1.0
			correction += right * side * anticipation * speed * 0.75
	correction = correction.limit_length(speed * 0.85)
	_crowd_offset = _crowd_offset.lerp(correction, 1.0 - exp(-10.0 * delta))
	var candidate := (velocity + _crowd_offset).limit_length(speed)
	# Do not let separation steer into scenery or cut a pathfinding corner.
	var probe_time := maxf(delta, 0.12)
	if not test_move(global_transform, candidate * probe_time):
		velocity = candidate
	else:
		_crowd_offset = Vector2.ZERO

var _reposition_goal := Vector2.ZERO
var _reposition_left := 0.0
var _reposition_side := 1.0

func begin_ranged_reposition(preferred_distance: float, duration: float = 1.0) -> bool:
	_reposition_left = 0.0
	if is_dying or not is_instance_valid(target) or move_speed <= 0.0: return false
	var away := target.global_position.direction_to(global_position)
	if away == Vector2.ZERO: away = Vector2.RIGHT
	_reposition_side = -_reposition_side
	var best_score := -INF
	var neighbors := EnemyCrowd.neighbors(self)
	var exclusions := EnemyNavigation.actor_exclusions(get_tree())
	for step in [0.65, 1.0]:
		var travel: float = clampf(move_speed * duration * step, 28.0, 125.0)
		for index in range(12):
			var direction := away.rotated(TAU * index / 12.0)
			var candidate := global_position + direction * travel
			if not _can_walk_segment(global_position, candidate): continue
			var query := PhysicsRayQueryParameters2D.create(candidate, target.global_position, EnemyNavigation.OBSTACLE_MASK)
			query.exclude = exclusions
			if not get_world_2d().direct_space_state.intersect_ray(query).is_empty(): continue
			var distance := candidate.distance_to(target.global_position)
			var score := -absf(distance - preferred_distance) + direction.dot(away.orthogonal()) * _reposition_side * 18.0 + travel * 0.12
			for sample in neighbors:
				score -= maxf(0.0, 65.0 - candidate.distance_to(sample.position)) * 1.5
			if score > best_score:
				best_score = score
				_reposition_goal = candidate
	if best_score == -INF: return false
	_reposition_left = duration
	return true

func process_ranged_reposition(delta: float) -> bool:
	if _reposition_left <= 0.0 or is_dying: return false
	_reposition_left = maxf(0.0, _reposition_left - delta)
	var offset := _reposition_goal - global_position
	if offset.length() < 5.0 or not _can_walk_segment(global_position, _reposition_goal):
		_reposition_left = 0.0
		velocity = Vector2.ZERO
		return false
	velocity = offset.normalized() * minf(move_speed, offset.length() / maxf(delta, 0.001))
	return true
