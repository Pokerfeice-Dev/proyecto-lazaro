extends CharacterBody2D
class_name Player

@export var stats: PlayerStats = PlayerStats.new()
@export var acceleration: float = 2000.0
@export var friction: float = 650
@export var dash_speed: float = 500
@export var dash_duration: float = 0.2
@export var projectile_scene: PackedScene = preload("res://Scenes/Projectiles/Projectile.tscn")
@export var weapon_scene: PackedScene = preload("res://Scenes/Weapon/main_weapon.tscn")
@export var second_weapon_scene: PackedScene = preload("res://Scenes/Weapon/second_weapon.tscn")

@export_category("Weapon Animation Offsets")
@export var animation_frame_offsets: Dictionary = {
	"idle_default": [
		Vector2(0, 0),
		Vector2(0, 1),
		Vector2(0, 2),
		Vector2(0, 1),
		Vector2(0, 0),
		Vector2(0, -1),
		Vector2(0, -2),
		Vector2(0, -1)
	]
}

@export_category("Camera Feedback")
@export var shake_intensity: float = 6.0
@export var shake_duration: float = 0.1
var shake_tween: Tween

@export_category("Damage Effect")
@export var damage_border_color: Color = Color(1.0, 0.0, 0.0, 1.0)
@export var damage_border_intensity: float = 0.9
var damage_canvas: CanvasLayer
var damage_rect: ColorRect

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var can_shoot: bool = true
var shoot_timer: Timer

var is_dashing: bool = false
var dash_timer: Timer
var dash_cd_timer: Timer
var dash_dir: Vector2 = Vector2.DOWN

var last_dir: String = "down"

var is_invulnerable: bool = false
var invuln_timer: Timer

var weapon_hide_timer: Timer

var active_weapon
var second_weapon
var _last_active_synergy_state: String = ""

func _ready() -> void:
	_init_timers()
	setup_damage_effect()
	_init_stats()
	add_to_group("player")
	_init_weapon()
	_apply_game_data_upgrades()
	_update_hud_health(stats.current_health, stats.max_health)
	_update_hud_scrap(GameData.scrap)
	
	var equip = get_node_or_null("Equipment")
	if equip:
		equip.equipment_changed.connect(_on_equipment_changed)
	_update_player_stats()

func _on_equipment_changed() -> void:
	_update_player_stats()

func _update_player_stats() -> void:
	var bonus_hp_percent = _get_equip_stat("max_health_percent", false)
	var new_max_hp = int(stats.base_max_health * (1.0 + bonus_hp_percent))
	if new_max_hp != stats.max_health:
		stats.update_max_health(new_max_hp)
		
	var bonus_speed_percent = _get_equip_stat("move_speed_percent", false)
	var flat_speed = _get_equip_stat("move_speed", false)
	stats.move_speed = (stats.base_move_speed + flat_speed) * (1.0 + bonus_speed_percent)
	
	_apply_synergy_weapon_override()

func _apply_synergy_weapon_override() -> void:
	if not active_weapon:
		return
	if not active_weapon.has_method("apply_synergy_weapon_override"):
		return
	var equip = get_node_or_null("Equipment")
	var active_weapon_id = get_active_ranged_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id)
	var override_path = SynergyManager.get_synergies_weapon_override(active_syns)
	_print_synergy_debug_status(active_syns, override_path)
	active_weapon.apply_synergy_weapon_override(override_path)

func _print_synergy_debug_status(active_syns: Array[String], override_path: String) -> void:
	var state_str = ",".join(active_syns) + ":" + override_path
	if _last_active_synergy_state == state_str:
		return
	_last_active_synergy_state = state_str
	
	if active_syns.is_empty():
		print("[SYNERGY DEBUG] No active synergies. Reverting to base weapon.")
		return
	print("[SYNERGY DEBUG] Active Synergies: ", active_syns, " | Weapon Override: ", override_path)

func _init_timers() -> void:
	_create_shoot_timer()
	_create_dash_timer()
	_create_invuln_timer()
	_create_weapon_hide_timer()

func _create_shoot_timer() -> void:
	shoot_timer = Timer.new()
	shoot_timer.one_shot = true
	add_child(shoot_timer)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)

func _create_dash_timer() -> void:
	dash_timer = Timer.new()
	dash_timer.one_shot = true
	add_child(dash_timer)
	dash_timer.timeout.connect(_on_dash_timer_timeout)

	dash_cd_timer = Timer.new()
	dash_cd_timer.one_shot = true
	add_child(dash_cd_timer)

func _create_invuln_timer() -> void:
	invuln_timer = Timer.new()
	invuln_timer.one_shot = true
	add_child(invuln_timer)
	invuln_timer.timeout.connect(_on_invuln_timeout)

func _create_weapon_hide_timer() -> void:
	weapon_hide_timer = Timer.new()
	weapon_hide_timer.one_shot = true
	add_child(weapon_hide_timer)

func _on_weapon_hide_timeout() -> void:
	pass

func _show_primary_weapon() -> void:
	if active_weapon: active_weapon.show()
	if second_weapon: second_weapon.hide()

func _show_secondary_weapon() -> void:
	if active_weapon: active_weapon.hide()
	if second_weapon: second_weapon.show()

func _init_stats() -> void:
	if not stats: stats = PlayerStats.new()
	stats.health_changed.connect(_on_health_changed)
	GameData.scrap_changed.connect(_on_scrap_changed)
	GameData.flesh_changed.connect(_on_flesh_changed)
	stats.player_died.connect(_on_died)

func _init_weapon() -> void:
	_init_primary_weapon()
	_init_secondary_weapon()
	_show_primary_weapon()

func _init_primary_weapon() -> void:
	if not weapon_scene: return
	active_weapon = weapon_scene.instantiate()
	add_child(active_weapon)

func _init_secondary_weapon() -> void:
	if not second_weapon_scene: return
	second_weapon = second_weapon_scene.instantiate()
	add_child(second_weapon)
	if GameData.has_method("unlock_codex_entry"):
		GameData.unlock_codex_entry("weapons", "second_weapon")

func _apply_game_data_upgrades() -> void:
	if active_weapon and active_weapon.has_method("get_damage"):
		GameData.apply_to_weapon(active_weapon)
	GameData.apply_to_melee(second_weapon)

func _physics_process(delta: float) -> void:
	_check_dash_input()
	_process_movement(delta)
	update_glock()
	_process_actions()
	move_and_slide()
	update_animation()

func _check_dash_input() -> void:
	if not Input.is_action_just_pressed("dash"): return
	if is_dashing: return
	if not dash_cd_timer.is_stopped(): return
	_start_dash()

func _start_dash() -> void:
	is_dashing = true
	dash_timer.start(dash_duration)
	dash_cd_timer.start(5.0)
	_set_dash_direction()

func _set_dash_direction() -> void:
	if velocity == Vector2.ZERO:
		dash_dir = _get_dir_vector(last_dir)
		return
	dash_dir = velocity.normalized()

func _process_movement(delta: float) -> void:
	if is_dashing:
		velocity = dash_dir * dash_speed
		return
	handle_movement(delta)

func _process_actions() -> void:
	if is_dashing: return
	handle_shooting()
	handle_melee()

func handle_melee() -> void:
	if not Input.is_action_just_pressed("attack_melee"): return
	if not second_weapon: return
	if not second_weapon.has_method("attack"): return
	_show_secondary_weapon()
	second_weapon.attack()

func setup_damage_effect() -> void:
	damage_canvas = CanvasLayer.new()
	damage_canvas.layer = 99
	add_child(damage_canvas)
	damage_rect = ColorRect.new()
	damage_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_damage_material()

func _apply_damage_material() -> void:
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = _get_damage_shader_code()
	mat.shader = shader
	mat.set_shader_parameter("border_color", damage_border_color)
	mat.set_shader_parameter("intensity", 0.0)
	damage_rect.material = mat
	damage_canvas.add_child(damage_rect)

func _get_damage_shader_code() -> String:
	return """
shader_type canvas_item;
uniform vec4 border_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float intensity = 0.0;
void fragment() {
	vec2 uv = UV;
	float d = distance(uv, vec2(0.5, 0.5));
	float alpha = smoothstep(0.35, 0.75, d) * intensity;
	COLOR = border_color;
	COLOR.a *= alpha;
}
"""

func handle_movement(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir == Vector2.ZERO:
		_apply_friction(delta)
		return
	_apply_acceleration(input_dir, delta)


func _apply_friction(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

func _apply_acceleration(input_dir: Vector2, delta: float) -> void:
	velocity = velocity.move_toward(input_dir * stats.move_speed, acceleration * delta)

func _update_last_dir(input_dir: Vector2) -> void:
	last_dir = _get_8_dir_string(input_dir)

func _get_8_dir_string(dir: Vector2) -> String:
	var angle = dir.angle()
	if angle < 0:
		angle += 2 * PI
	var sector = int(round(angle / (PI / 4.0))) % 8
	match sector:
		0: return "right"
		1: return "down_right"
		2: return "down"
		3: return "down_left"
		4: return "left"
		5: return "up_left"
		6: return "up"
		7: return "up_right"
	return "down"


func handle_shooting() -> void:
	if not can_shoot: return
	if not Input.is_action_pressed("shoot"): return
	var shoot_dir = (get_global_mouse_position() - global_position).normalized()
	if shoot_dir == Vector2.ZERO: return
	fire_projectile(shoot_dir)

func _get_equip_stat(stat_name: String, is_main: bool = true) -> float:
	var equip = get_node_or_null("Equipment")
	if not equip:
		return 0.0
	var bonus = 0.0
	var char_stats = equip.get_character_stats()
	if char_stats.has(stat_name):
		bonus += float(char_stats[stat_name])
	
	if is_main:
		var w_stats = equip.get_main_weapon_stats()
		if w_stats.has(stat_name):
			bonus += float(w_stats[stat_name])
	else:
		var w_stats = equip.get_secondary_weapon_stats()
		if w_stats.has(stat_name):
			bonus += float(w_stats[stat_name])
			
	var active_weapon_id = get_active_ranged_weapon_id() if is_main else get_active_melee_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id)
	bonus += SynergyManager.get_synergies_stat_modifier(active_syns, stat_name)
	return bonus

func get_active_ranged_weapon_id() -> String:
	if not active_weapon:
		return ""
	if active_weapon.has_method("get_base_weapon_id"):
		return active_weapon.get_base_weapon_id()
	var cur = active_weapon.get("current_weapon")
	if not cur:
		return ""
	return cur.get("id") if "id" in cur else ""

func get_active_melee_weapon_id() -> String:
	if not second_weapon:
		return ""
	var cur = second_weapon.get("current_weapon")
	if not cur:
		return ""
	return cur.get("id") if "id" in cur else ""

func fire_projectile(dir: Vector2) -> void:
	_show_primary_weapon()
	can_shoot = false
	var base_aps = 1.0
	var bonus_aps_pct = _get_equip_stat("attack_speed")
	var final_aps = base_aps * (1.0 + bonus_aps_pct)
	var final_fire_rate = 1.0 / maxf(0.1, final_aps)
	var fire_point = global_position
	var p_scene = projectile_scene
	var dmg = (10.0 + _get_equip_stat("damage")) * (1.0 + _get_equip_stat("damage_multiplier"))
	var p_speed = 600.0 + _get_equip_stat("projectile_speed")
	var bullets = 1 + int(_get_equip_stat("bullet_count"))
	var spread = 0.0 + _get_equip_stat("cone_spread_angle")
	var piercing = 0 + int(_get_equip_stat("piercing"))
	var crit_chance = 0.0 + _get_equip_stat("crit_chance")
	var crit_damage = 2.0 + _get_equip_stat("crit_damage")
	var lifetime = 3.0 + _get_equip_stat("lifetime")

	if active_weapon:
		var w_base_aps = _get_weapon_attack_speed()
		var w_final_aps = w_base_aps * (1.0 + bonus_aps_pct)
		final_fire_rate = 1.0 / maxf(0.1, w_final_aps)
		p_scene = _get_weapon_proj_scene(p_scene)
		dmg = (_get_weapon_damage() + _get_equip_stat("damage")) * (_get_weapon_damage_multiplier() + _get_equip_stat("damage_multiplier"))
		p_speed = _get_weapon_proj_speed() + _get_equip_stat("projectile_speed")
		bullets = _get_weapon_bullets() + int(_get_equip_stat("bullet_count"))
		spread = maxf(0.0, _get_weapon_spread() - _get_equip_stat("cone_spread_angle"))
		piercing = _get_weapon_piercing() + int(_get_equip_stat("piercing"))
		crit_chance = _get_weapon_crit_chance() + _get_equip_stat("crit_chance")
		crit_damage = _get_weapon_crit_damage() + _get_equip_stat("crit_damage")
		lifetime = _get_weapon_lifetime() + _get_equip_stat("lifetime")
		_play_weapon_effects()
		fire_point = _get_weapon_mark(fire_point)

	var equip = get_node_or_null("Equipment")
	var active_weapon_id = get_active_ranged_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id)
	var override_scene = SynergyManager.get_synergies_projectile_override(active_syns)
	if override_scene:
		p_scene = override_scene

	if not p_scene:
		return
	shoot_timer.start(final_fire_rate)
	_spawn_bullets(p_scene, bullets, spread, dir, dmg, p_speed, fire_point, piercing, crit_chance, crit_damage, lifetime)
	apply_camera_shake()

func _get_weapon_proj_scene(fallback: PackedScene) -> PackedScene:
	if not active_weapon.has_method("get_projectile_scene"): return fallback
	var ws = active_weapon.get_projectile_scene()
	if not ws: return fallback
	return ws

func _get_weapon_attack_speed() -> float:
	if not active_weapon.has_method("get_attack_speed"): return 0.5
	return active_weapon.get_attack_speed()

func _get_weapon_damage_multiplier() -> float:
	if not active_weapon.has_method("get_damage_multiplier"): return 1.0
	return active_weapon.get_damage_multiplier()

func _get_weapon_damage() -> float:
	if not active_weapon.has_method("get_damage"): return 10.0
	return active_weapon.get_damage()

func _get_weapon_proj_speed() -> float:
	if not active_weapon.has_method("get_projectile_speed"): return 600.0
	return active_weapon.get_projectile_speed()

func _get_weapon_bullets() -> int:
	if not active_weapon.has_method("get_bullet_count"): return 1
	return active_weapon.get_bullet_count()

func _get_weapon_spread() -> float:
	if not active_weapon.has_method("get_spread_angle"): return 0.0
	return active_weapon.get_spread_angle()

func _get_weapon_piercing() -> int:
	if not active_weapon.has_method("get_piercing"): return 0
	return active_weapon.get_piercing()

func _get_weapon_crit_chance() -> float:
	if not active_weapon.has_method("get_crit_chance"): return 0.0
	return active_weapon.get_crit_chance()

func _get_weapon_crit_damage() -> float:
	if not active_weapon.has_method("get_crit_damage"): return 2.0
	return active_weapon.get_crit_damage()

func _get_weapon_lifetime() -> float:
	if not active_weapon.has_method("get_lifetime"): return 3.0
	return active_weapon.get_lifetime()

func _play_weapon_effects() -> void:
	if active_weapon and active_weapon.has_method("play_shoot_effects"):
		active_weapon.play_shoot_effects()
	
	# Fallback para armas viejas que no usan el nuevo sistema
	var weapon_anim = active_weapon.get_node_or_null("Weapon_Sprites")
	if weapon_anim:
		weapon_anim.stop()
		weapon_anim.play("shoot")
		
	var w_sound = active_weapon.get_node_or_null("Bullet_sound")
	if w_sound and w_sound.has_method("play"):
		w_sound.play()

func _get_weapon_mark(fallback: Vector2) -> Vector2:
	if active_weapon and active_weapon.has_method("get_bullet_spawn_pos"):
		var pos = active_weapon.get_bullet_spawn_pos(fallback)
		if pos != fallback: return pos
		
	var mark_node = active_weapon.get_node_or_null("Bullet_mark_right")
	if not mark_node: return fallback
	return mark_node.global_position

func _spawn_bullets(p_scene: PackedScene, count: int, spread: float, dir: Vector2, dmg: float, p_speed: float, spawn_pos: Vector2, piercing: int, crit_chance: float, crit_damage: float, lifetime: float) -> void:
	var start_angle = _get_start_angle(dir, count, spread)
	var step_angle = _get_step_angle(count, spread)
	_instantiate_bullets(p_scene, count, start_angle, step_angle, dir, dmg, p_speed, spawn_pos, piercing, crit_chance, crit_damage, lifetime)

func _get_start_angle(dir: Vector2, count: int, spread: float) -> float:
	var angle = dir.angle()
	if count <= 1: return angle
	return angle - (deg_to_rad(spread) / 2.0)

func _get_step_angle(count: int, spread: float) -> float:
	if count <= 1: return 0.0
	return deg_to_rad(spread) / float(count - 1)

func _instantiate_bullets(p_scene: PackedScene, count: int, start_angle: float, step_angle: float, dir: Vector2, dmg: float, p_speed: float, spawn_pos: Vector2, piercing: int, crit_chance: float, crit_damage: float, lifetime: float) -> void:
	for i in range(count):
		_spawn_single_bullet(p_scene, i, count, start_angle, step_angle, dir, dmg, p_speed, spawn_pos, piercing, crit_chance, crit_damage, lifetime)

func _spawn_single_bullet(p_scene: PackedScene, i: int, count: int, start_angle: float, step_angle: float, dir: Vector2, dmg: float, p_speed: float, spawn_pos: Vector2, piercing: int, crit_chance: float, crit_damage: float, lifetime: float) -> void:
	var final_dir = dir
	if count > 1:
		final_dir = Vector2.RIGHT.rotated(start_angle + (step_angle * float(i)))
	var proj = p_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = spawn_pos
	
	var final_dmg = dmg
	var is_crit = false
	if randf() <= crit_chance:
		final_dmg *= crit_damage
		is_crit = true
		
	proj.setup(final_dir, final_dmg, "enemy", is_crit)
	if "speed" in proj: proj.speed = p_speed
	if "piercing" in proj: proj.piercing = piercing
	if "lifetime" in proj: proj.lifetime = lifetime
	_assign_homing_target_if_supported(proj)

func _assign_homing_target_if_supported(proj: Node2D) -> void:
	if not proj.has_method("set_homing_target"):
		return
	var target = _get_cone_target_enemy()
	if target:
		proj.set_homing_target(target)

func _get_cone_target_enemy() -> Node2D:
	if not active_weapon:
		return null
	var cur = active_weapon.get("current_weapon")
	if not cur:
		return null
	var cone_aim = _get_cone_aim_node(cur)
	if not cone_aim:
		return null
		
	# Programmatic safety configuration
	cone_aim.monitoring = true
	cone_aim.collision_mask = 2 # Detect enemies (layer 2)
	
	var bodies = cone_aim.get_overlapping_bodies()
	var target = _find_closest_enemy_in_list(bodies)
	print("[CONE AIM DEBUG] Overlapping bodies: ", bodies.size(), " | Selected Homing Target: ", target.name if target else "None")
	return target

func _get_cone_aim_node(cur: Node) -> Area2D:
	var node = cur.get_node_or_null("Cone_Aim")
	if not node:
		node = cur.get_node_or_null("cone_aim")
	return node as Area2D

func _find_closest_enemy_in_list(bodies: Array) -> Node2D:
	var closest: Node2D = null
	var min_dist = INF
	for body in bodies:
		if not body.is_in_group("enemy"):
			continue
		var dist = global_position.distance_to(body.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = body
	return closest

func apply_camera_shake() -> void:
	var camera = get_viewport().get_camera_2d()
	if not camera: return
	_reset_camera_shake(camera)
	_start_camera_shake(camera)

func _reset_camera_shake(camera: Camera2D) -> void:
	if not shake_tween: return
	if not shake_tween.is_valid(): return
	shake_tween.kill()
	camera.offset = Vector2.ZERO

func _start_camera_shake(camera: Camera2D) -> void:
	shake_tween = create_tween()
	var random_offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	shake_tween.tween_property(camera, "offset", random_offset, shake_duration / 2.0).set_trans(Tween.TRANS_SINE)
	shake_tween.tween_property(camera, "offset", Vector2.ZERO, shake_duration / 2.0).set_trans(Tween.TRANS_SINE)

func update_glock() -> void:
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()
	var orbit_radius = 25.0
	_update_primary_weapon_pivot(mouse_pos, dir, orbit_radius)
	_update_secondary_weapon_pivot(mouse_pos, dir, orbit_radius)

func _update_primary_weapon_pivot(mouse_pos: Vector2, dir: Vector2, _orbit_radius: float) -> void:
	if not active_weapon:
		return
	var base_pos = _get_weapon_base_position(dir)
	active_weapon.look_at(mouse_pos)
	active_weapon.position = base_pos
	_flip_weapon(active_weapon, dir)
	active_weapon.show_behind_parent = dir.y < 0

func _update_secondary_weapon_pivot(mouse_pos: Vector2, dir: Vector2, _orbit_radius: float) -> void:
	if not second_weapon:
		return
	var base_pos = _get_weapon_base_position(dir)
	second_weapon.look_at(mouse_pos)
	second_weapon.position = base_pos
	_flip_weapon(second_weapon, dir)
	second_weapon.show_behind_parent = dir.y < 0

func _get_weapon_base_position(dir: Vector2) -> Vector2:
	var base_pos = _get_static_weapon_mark_position(dir)
	var anim_offset = _get_animation_offset()
	var final_offset = _apply_flip_to_offset(anim_offset, dir.x < 0)
	return base_pos + final_offset

func _get_static_weapon_mark_position(dir: Vector2) -> Vector2:
	var mark_node = get_node_or_null("Weapon_mark")
	if not mark_node:
		return Vector2.ZERO
	return _apply_flip_to_offset(mark_node.position, dir.x < 0)

func _get_animation_offset() -> Vector2:
	if not anim_sprite:
		return Vector2.ZERO
	return _calculate_frame_offset(anim_sprite.animation, anim_sprite.frame)

func _calculate_frame_offset(anim_name: String, frame_idx: int) -> Vector2:
	var offsets = _get_offsets_for_animation(anim_name)
	if offsets.is_empty():
		return Vector2.ZERO
	if frame_idx < 0 or frame_idx >= offsets.size():
		return Vector2.ZERO
	return offsets[frame_idx]

func _get_offsets_for_animation(anim_name: String) -> Array:
	if animation_frame_offsets.has(anim_name):
		return animation_frame_offsets[anim_name]
	if anim_name.begins_with("idle") and animation_frame_offsets.has("idle_default"):
		return animation_frame_offsets["idle_default"]
	return []

func _apply_flip_to_offset(offset: Vector2, should_flip: bool) -> Vector2:
	if should_flip:
		return Vector2(-offset.x, offset.y)
	return offset


func _flip_weapon(weapon: Node2D, dir: Vector2) -> void:
	var base_scale = abs(weapon.scale.x)
	if dir.x < 0:
		weapon.scale.y = -base_scale
		return
	weapon.scale.y = base_scale

func update_animation() -> void:
	_update_facing_direction()
	if not anim_sprite:
		return
	_play_player_sprite_animation()

func _update_facing_direction() -> void:
	var mouse_dir = (get_global_mouse_position() - global_position).normalized()
	if mouse_dir != Vector2.ZERO:
		last_dir = _get_8_dir_string(mouse_dir)


func _play_player_sprite_animation() -> void:
	if is_dashing:
		_play_dash_animation()
		return
	if velocity.length() > 50:
		_play_run_animation()
		return
	_play_idle_animation()

func _play_dash_animation() -> void:
	var suffix = _get_dash_dir_suffix(last_dir)
	anim_sprite.play("Dash_" + suffix)

func _get_dash_dir_suffix(dir_str: String) -> String:
	if dir_str == "down_left":
		return "left_down"
	if dir_str == "up_left":
		return "left_up"
	if dir_str == "down_right":
		return "right_down"
	if dir_str == "up_right":
		return "right_up"
	return dir_str

func _play_run_animation() -> void:
	if _is_diagonal(last_dir):
		anim_sprite.play("run_diagonal_" + last_dir)
		return
	anim_sprite.play("run_" + last_dir)

func _play_idle_animation() -> void:
	if _is_diagonal(last_dir):
		anim_sprite.play("idle_diagonal_" + last_dir)
		return
	anim_sprite.play("idle_" + last_dir)

func _is_diagonal(dir_str: String) -> bool:
	return dir_str in ["up_left", "up_right", "down_left", "down_right"]


func _get_dir_vector(dir_str: String) -> Vector2:
	if dir_str == "up": return Vector2.UP
	if dir_str == "down": return Vector2.DOWN
	if dir_str == "right": return Vector2.RIGHT
	if dir_str == "left": return Vector2.LEFT
	if dir_str == "up_right": return Vector2(1, -1).normalized()
	if dir_str == "up_left": return Vector2(-1, -1).normalized()
	if dir_str == "down_right": return Vector2(1, 1).normalized()
	if dir_str == "down_left": return Vector2(-1, 1).normalized()
	return Vector2.DOWN


func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func _on_dash_timer_timeout() -> void:
	is_dashing = false

func take_damage(amount: int) -> void:
	if is_invulnerable: return
	is_invulnerable = true
	
	var armor = _get_equip_stat("armor", false)
	var final_amount = maxi(1, amount - int(armor))
	
	invuln_timer.start(0.5)
	stats.take_damage(final_amount)
	_show_damage_text(final_amount)
	_play_hurt_sound()
	_animate_damage_vignette()
	_animate_damage_flash()

func _show_damage_text(amount: int) -> void:
	var label = Label.new()
	label.text = "-%d" % amount
	label.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0))
	label.add_theme_constant_override("outline_size", 4)
	
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(100, 30)
	label.position = Vector2(-50, -15)
	
	var floating_node = Node2D.new()
	floating_node.global_position = global_position + Vector2(randf_range(-15.0, 15.0), -40.0)
	floating_node.add_child(label)
	
	get_tree().current_scene.call_deferred("add_child", floating_node)
	
	var tween = get_tree().create_tween().bind_node(floating_node).set_parallel(true)
	tween.tween_property(floating_node, "global_position", floating_node.global_position + Vector2(0, -40), 0.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.chain().tween_callback(floating_node.queue_free)

func _play_hurt_sound() -> void:
	var hurt_sound = get_node_or_null("Hurt_sound")
	if not hurt_sound: hurt_sound = get_node_or_null("HurtSound")
	if not hurt_sound: return
	if not hurt_sound.has_method("play"): return
	hurt_sound.play()

func _animate_damage_vignette() -> void:
	if not damage_rect: return
	if not damage_rect.material: return
	var mat = damage_rect.material as ShaderMaterial
	mat.set_shader_parameter("border_color", damage_border_color)
	var t = create_tween()
	t.tween_method(_tween_damage_intensity.bind(mat), damage_border_intensity, 0.0, 0.6).set_trans(Tween.TRANS_SINE)

func _tween_damage_intensity(val: float, mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("intensity", val)

func _animate_damage_flash() -> void:
	if not anim_sprite: return
	var original_modulate = anim_sprite.modulate
	anim_sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(anim_sprite, "modulate", original_modulate, 0.5)

func _on_invuln_timeout() -> void:
	is_invulnerable = false

func _on_health_changed(new_health: int, max_health: int) -> void:
	_update_hud_health(new_health, max_health)

func _update_hud_health(new_health: int, max_health: int) -> void:
	var huds = get_tree().get_nodes_in_group("hud")
	if huds.is_empty(): return
	huds[0].update_health(new_health, max_health)

func _on_scrap_changed(amount: int) -> void:
	_update_hud_scrap(amount)

func _update_hud_scrap(amount: int) -> void:
	var huds = get_tree().get_nodes_in_group("hud")
	if huds.is_empty(): return
	huds[0].update_scrap(amount)

func _on_flesh_changed(amount: int) -> void:
	_update_hud_flesh(amount)

func _update_hud_flesh(amount: int) -> void:
	var huds = get_tree().get_nodes_in_group("hud")
	if huds.is_empty(): return
	huds[0].update_flesh(amount)

func _on_died() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	hide()
	GameData.clear_items()
	_show_death_screen()

func _show_death_screen() -> void:
	var overlay = _build_death_overlay()
	get_tree().root.add_child(overlay)
	_animate_death_overlay(overlay)

func _build_death_overlay() -> CanvasLayer:
	var canvas = CanvasLayer.new()
	canvas.layer = 200
	var root = _build_death_root()
	canvas.add_child(root)
	root.add_child(_build_death_bg())
	root.add_child(_build_death_label())
	root.add_child(_build_death_sub_label())
	return canvas

func _build_death_root() -> Control:
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return root

func _build_death_bg() -> ColorRect:
	var bg = ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0, 0, 0, 0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bg

func _build_death_label() -> Label:
	var lbl = Label.new()
	lbl.name = "DeathLabel"
	lbl.text = "MORISTE"
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	lbl.grow_vertical = Control.GROW_DIRECTION_BOTH
	lbl.offset_left = -400.0
	lbl.offset_right = 400.0
	lbl.offset_top = -80.0
	lbl.offset_bottom = 80.0
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 96)
	lbl.add_theme_color_override("font_color", Color(1, 0.1, 0.1, 0))
	lbl.add_theme_color_override("font_outline_color", Color(0.6, 0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 6)
	return lbl

func _build_death_sub_label() -> Label:
	var sub = Label.new()
	sub.name = "SubLabel"
	sub.text = "Volviendo al laboratorio..."
	sub.set_anchors_preset(Control.PRESET_CENTER)
	sub.grow_horizontal = Control.GROW_DIRECTION_BOTH
	sub.offset_left = -300.0
	sub.offset_right = 300.0
	sub.offset_top = 60.0
	sub.offset_bottom = 110.0
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 28)
	sub.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	return sub

func _animate_death_overlay(canvas: CanvasLayer) -> void:
	var root: Control = canvas.get_child(0)
	var bg: ColorRect = root.get_node("BG")
	var lbl: Label = root.get_node("DeathLabel")
	var sub: Label = root.get_node("SubLabel")
	var t = canvas.create_tween().set_parallel(false)
	_setup_show_death_animation(t, bg, lbl, sub)
	_setup_pulse_death_animation(t, lbl)
	_setup_hide_death_animation(t, bg, lbl, sub)
	t.finished.connect(_on_death_animation_finished.bind(canvas))

func _setup_show_death_animation(t: Tween, bg: ColorRect, lbl: Label, _sub: Label) -> void:
	t.tween_property(bg, "color", Color(0, 0, 0, 0.85), 0.5)
	t.tween_property(lbl, "theme_override_colors/font_color", Color(1, 0.1, 0.1, 1), 0.3)
	t.parallel().tween_property(lbl, "theme_override_colors/font_outline_color", Color(0.6, 0, 0, 1), 0.3)

func _setup_pulse_death_animation(t: Tween, lbl: Label) -> void:
	t.tween_property(lbl, "scale", Vector2(1.08, 1.08), 0.15).set_trans(Tween.TRANS_SINE)
	t.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)

func _setup_hide_death_animation(t: Tween, bg: ColorRect, lbl: Label, sub: Label) -> void:
	t.tween_property(sub, "theme_override_colors/font_color", Color(1, 1, 1, 0.8), 0.4)
	t.tween_interval(1.4)
	t.tween_property(bg, "color", Color(0, 0, 0, 0), 0.5)
	t.parallel().tween_property(lbl, "theme_override_colors/font_color", Color(1, 0.1, 0.1, 0), 0.5)
	t.parallel().tween_property(sub, "theme_override_colors/font_color", Color(1, 1, 1, 0), 0.5)

func _on_death_animation_finished(canvas: CanvasLayer) -> void:
	canvas.queue_free()
	SceneTransition.change_scene("res://Scenes/Rooms/lab_room.tscn")

func _unhandled_input(event: InputEvent) -> void:
	_handle_debug_cheats(event)

func _handle_debug_cheats(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed:
		return
	_process_debug_keycode(event.keycode)

func _process_debug_keycode(keycode: int) -> void:
	if keycode == KEY_F1:
		_cheat_synergy_items()
	if keycode == KEY_F2:
		_cheat_roadkill_items()

func _cheat_synergy_items() -> void:
	var inventory_node = get_node_or_null("Inventory")
	if not inventory_node:
		return
	var colmena = load("res://Art/Items/Weapons/Item7_Colmena.tres") as ItemData
	var cerebro = load("res://Art/Items/Weapons/Item3.tres") as ItemData
	var cabeza = load("res://Art/Items/Weapons/Item8_CabezaHumana.tres") as ItemData
	_add_item_if_valid(inventory_node, colmena)
	_add_item_if_valid(inventory_node, cerebro)
	_add_item_if_valid(inventory_node, cabeza)
	print("Cheated items added to inventory!")

func _cheat_roadkill_items() -> void:
	var inventory_node = get_node_or_null("Inventory")
	if not inventory_node:
		return
	var moto = load("res://Art/Items/Weapons/Item6.tres") as ItemData
	var pulmones = load("res://Art/Items/Weapons/Item5.tres") as ItemData
	var sierra = load("res://Art/Items/Weapons/Item9_SierraCircular.tres") as ItemData
	_add_item_if_valid(inventory_node, moto)
	_add_item_if_valid(inventory_node, pulmones)
	_add_item_if_valid(inventory_node, sierra)
	print("Roadkill cheated items added to inventory!")

func _add_item_if_valid(inventory_node: Node, item: ItemData) -> void:
	if item:
		inventory_node.add_item(item)
