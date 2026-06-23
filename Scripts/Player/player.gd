extends CharacterBody2D
class_name Player

@export var stats: PlayerStats = PlayerStats.new()
@export var acceleration: float = 2000.0
@export var friction: float = 650
@export var dash_speed: float = 500
@export var dash_duration: float = 0.3
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
var minigun_hold_time: float = 0.0
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
var left_melee_weapon
var is_furia_active: bool = false
var furia_timer: Timer
var trituradora_energy: float = 0.0
const TRITURADORA_MAX_ENERGY: float = 600.0
var trituradora_shockwave_ready: bool = false
var _last_active_synergy_state: String = ""

var first_hit_taken_in_room: bool = false
var is_blindaje_reactivo_active: bool = false
var blindaje_reactivo_timer: Timer = null
var dash_start_pos: Vector2 = Vector2.ZERO

var _default_modulate: Color = Color.WHITE
var _flash_tween: Tween = null

func _ready() -> void:
	_init_timers()
	setup_damage_effect()
	_init_stats()
	add_to_group("player")
	_initialize_protocols()
	_init_weapon()
	_apply_game_data_upgrades()
	_update_hud_health(stats.current_health, stats.max_health)
	_update_hud_scrap(GameData.scrap)
	
	if anim_sprite:
		_default_modulate = anim_sprite.modulate
		_default_modulate.a = 1.0
		
	var equip = get_node_or_null("Equipment")
	if equip:
		equip.equipment_changed.connect(_on_equipment_changed)
	_update_player_stats()

func _on_equipment_changed() -> void:
	_update_player_stats()

func _update_player_stats() -> void:
	var bonus_hp_percent = _get_equip_stat("max_health_percent", false)
	var integrity_lvl = GameData.core_upgrades.get("integridad_estructural", 0)
	var extra_hp = integrity_lvl * 2
	var new_max_hp = int(stats.base_max_health * (1.0 + bonus_hp_percent)) + extra_hp
	if new_max_hp != stats.max_health:
		stats.update_max_health(new_max_hp)
		
	var bonus_speed_percent = _get_equip_stat("move_speed_percent", false)
	var flat_speed = _get_equip_stat("move_speed", false)
	var servo_lvl = GameData.core_upgrades.get("servomotores", 0)
	var perm_speed_mult = 1.0 + (servo_lvl * 0.01)
	stats.move_speed = (stats.base_move_speed + flat_speed) * (1.0 + bonus_speed_percent) * perm_speed_mult
	
	_apply_synergy_weapon_override()
	
	if _is_bestia_de_caza_active():
		if not left_melee_weapon:
			_init_left_melee_weapon()
		if active_weapon:
			active_weapon.hide()
		if second_weapon:
			second_weapon.show()
		if left_melee_weapon:
			left_melee_weapon.show()
	else:
		if left_melee_weapon:
			left_melee_weapon.queue_free()
			left_melee_weapon = null
		if active_weapon:
			active_weapon.show()
			
	if not _is_trituradora_active():
		trituradora_shockwave_ready = false
		trituradora_energy = 0.0
		if not is_furia_active:
			self.modulate = Color(1, 1, 1)
			
	_check_and_trigger_first_time_synergies()

func _check_and_trigger_first_time_synergies() -> void:
	var equip = get_node_or_null("Equipment")
	if not equip:
		return
	var active_weapon_id = get_active_ranged_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, true)
	
	for syn_id in active_syns:
		_process_potential_first_time_synergy(syn_id)

func _process_potential_first_time_synergy(syn_id: String) -> void:
	if GameData.activated_synergies.has(syn_id):
		return
	
	GameData.activated_synergies.append(syn_id)
	GameData.save_game()
	
	_spawn_synergy_popup(syn_id)

func _spawn_synergy_popup(syn_id: String) -> void:
	var def = SynergyManager.SYNERGIES.get(syn_id, {})
	var syn_name = def.get("name", syn_id)
	var syn_desc = def.get("description", "")
	
	var popup_script = load("res://Scripts/UI/synergy_popup.gd")
	if not popup_script:
		return
		
	var popup = Node.new()
	popup.set_script(popup_script)
	popup.setup(syn_name, syn_desc)
	
	get_tree().paused = true
	get_tree().root.add_child(popup)

func _apply_synergy_weapon_override() -> void:
	if not active_weapon:
		return
	if not active_weapon.has_method("apply_synergy_weapon_override"):
		return
	var equip = get_node_or_null("Equipment")
	var active_weapon_id = get_active_ranged_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, true)
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
	_create_furia_timer()
	
	blindaje_reactivo_timer = Timer.new()
	blindaje_reactivo_timer.one_shot = true
	add_child(blindaje_reactivo_timer)
	blindaje_reactivo_timer.timeout.connect(func(): is_blindaje_reactivo_active = false)

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
	if _is_bestia_de_caza_active():
		if active_weapon: active_weapon.hide()
		if second_weapon: second_weapon.show()
		if left_melee_weapon: left_melee_weapon.show()
		return
	if active_weapon: active_weapon.show()
	if second_weapon: second_weapon.hide()

func _show_secondary_weapon() -> void:
	if _is_bestia_de_caza_active():
		if active_weapon: active_weapon.hide()
		if second_weapon: second_weapon.show()
		if left_melee_weapon: left_melee_weapon.show()
		return
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
	_update_minigun_hold_time(delta)
	_check_dash_input()
	_process_movement(delta)
	update_glock()
	_update_camera_drift(delta)
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
	dash_start_pos = global_position
	set_collision_mask_value(2, false)
	dash_timer.start(dash_duration)
	var bonus_cd_pct = _get_equip_stat("dash_cooldown_percent", false)
	var final_cd = 5.0 * (1.0 + bonus_cd_pct)
	dash_cd_timer.start(final_cd)
	_set_dash_direction()
	_play_dash_sound()
	if _is_bestia_de_caza_active():
		_start_furia()
	if _is_trituradora_active() and trituradora_shockwave_ready:
		_trigger_trituradora_shockwave()

func _set_dash_direction() -> void:
	if velocity == Vector2.ZERO:
		dash_dir = _get_dir_vector(last_dir)
		return
	dash_dir = velocity.normalized()

func _process_movement(delta: float) -> void:
	if is_dashing:
		var bonus_dash_speed_pct = _get_equip_stat("dash_speed_percent", false)
		var final_dash_speed = dash_speed * (1.0 + bonus_dash_speed_pct)
		velocity = dash_dir * final_dash_speed
		return
	handle_movement(delta)
	if not is_dashing:
		_accumulate_trituradora_energy(delta)

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
	var final_speed = stats.move_speed
	if _is_minigun_active() and Input.is_action_pressed("shoot") and can_shoot:
		final_speed = _apply_minigun_speed_penalty(final_speed)
	velocity = velocity.move_toward(input_dir * final_speed, acceleration * delta)

func _apply_minigun_speed_penalty(base_val: float) -> float:
	var level = _get_minigun_level()
	if level == 1:
		return base_val * 0.85
	if level == 2:
		return base_val * 0.80
	if level == 3:
		return base_val * 0.50
	return base_val

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
	if _is_bestia_de_caza_active():
		if Input.is_action_just_pressed("shoot"):
			_attack_left_melee()
		return
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
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, is_main)
	bonus += SynergyManager.get_synergies_stat_modifier(active_syns, stat_name)
	
	if stat_name == "attack_speed":
		if is_furia_active:
			bonus += 0.50
		if GameData.get_active_protocol() == "furia_de_titanio" and stats.current_health <= stats.max_health * 0.3:
			bonus += 0.25
		
	if is_main:
		bonus += _get_minigun_stat_bonus(stat_name)
		
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
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, true)
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
	if "fragmentation_chance" in proj:
		proj.fragmentation_chance = _get_fragmentation_chance()
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

func _update_camera_drift(delta: float) -> void:
	var camera = get_node_or_null("Camera2D")
	if not camera: return
	
	var mouse_offset = get_local_mouse_position()
	var weight = 0.18
	var target_local_pos = mouse_offset * weight
	var max_offset = 120.0
	
	if target_local_pos.length() > max_offset:
		target_local_pos = target_local_pos.normalized() * max_offset
		
	camera.position = camera.position.lerp(target_local_pos, 1.0 - exp(-7.0 * delta))

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
	var base_pos = _get_weapon_base_position(dir)
	if second_weapon:
		second_weapon.look_at(mouse_pos)
		second_weapon.position = base_pos
		_flip_weapon(second_weapon, dir)
		second_weapon.show_behind_parent = dir.y < 0
	if left_melee_weapon:
		left_melee_weapon.look_at(mouse_pos)
		left_melee_weapon.position = base_pos
		_flip_weapon(left_melee_weapon, dir)
		left_melee_weapon.show_behind_parent = dir.y < 0

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


func _on_furia_timeout() -> void:
	is_furia_active = false
	if trituradora_shockwave_ready:
		self.modulate = Color(0.2, 0.8, 1.0)
	else:
		self.modulate = Color(1, 1, 1)
	set_collision_mask_value(2, true)

func _accumulate_trituradora_energy(delta: float) -> void:
	if not _is_trituradora_active():
		return
	if trituradora_shockwave_ready:
		return
	var moved_dist = velocity.length() * delta
	if moved_dist > 0.01:
		trituradora_energy += moved_dist
		if trituradora_energy >= TRITURADORA_MAX_ENERGY:
			trituradora_energy = TRITURADORA_MAX_ENERGY
			trituradora_shockwave_ready = true
			_play_shockwave_ready_effect()

func _play_shockwave_ready_effect() -> void:
	if not is_furia_active:
		self.modulate = Color(0.2, 0.8, 1.0)

func _is_trituradora_active() -> bool:
	var equip = get_node_or_null("Equipment")
	if not equip:
		return false
	var active_syns = SynergyManager.get_active_synergies(equip, "")
	return "trituradora_biomecanica" in active_syns

func _trigger_trituradora_shockwave() -> void:
	trituradora_shockwave_ready = false
	trituradora_energy = 0.0
	self.modulate = Color(1, 1, 1)
	
	# Invulnerability for 0.5s
	is_invulnerable = true
	invuln_timer.start(0.5)
	var original_modulate = self.modulate
	self.modulate = Color(0.2, 0.8, 1.0, 0.6)
	var tween = create_tween()
	tween.tween_property(self, "modulate", original_modulate, 0.5)
	
	# Damage and knockback area attack
	var base_dmg = 50.0
	var dmg_radius = 150.0
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy == null or not enemy.has_method("take_damage"):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < dmg_radius:
			enemy.take_damage(int(base_dmg))
			if enemy.has_method("apply_knockback"):
				var dir = (enemy.global_position - global_position).normalized()
				if dir == Vector2.ZERO: dir = Vector2.UP
				enemy.apply_knockback(250.0, dir)
				
	# Spawn shockwave visual effect
	var wave = load("res://Scripts/Effects/furia_shockwave.gd").new()
	wave.global_position = global_position
	wave.max_radius = dmg_radius
	wave.set_meta("color_fill", Color(0.2, 0.8, 1.0, 0.3))
	wave.set_meta("color_stroke", Color(0.4, 0.9, 1.0, 0.7))
	get_tree().current_scene.add_child(wave)

func _start_furia() -> void:
	is_furia_active = true
	if furia_timer:
		furia_timer.start(3.0)
	self.modulate = Color(1.0, 0.2, 0.2)
	set_collision_mask_value(2, false)

func _apply_thorns_knockback(force: float) -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if not enemy.has_method("apply_knockback"):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < 80.0:
			var dir = (enemy.global_position - global_position).normalized()
			if dir == Vector2.ZERO:
				dir = Vector2.UP
			enemy.apply_knockback(force, dir)

func _on_flesh_collected() -> void:
	var heal_amt = int(_get_equip_stat("heal_on_flesh", false))
	if heal_amt > 0:
		stats.heal(heal_amt)

func _is_bestia_de_caza_active() -> bool:
	var equip = get_node_or_null("Equipment")
	if not equip:
		return false
	var active_syns = SynergyManager.get_active_synergies(equip, "")
	return "bestia_de_caza" in active_syns

func _attack_left_melee() -> void:
	if not left_melee_weapon:
		return
	if not left_melee_weapon.has_method("attack"):
		return
	_show_secondary_weapon()
	left_melee_weapon.attack()

func _init_left_melee_weapon() -> void:
	if not second_weapon_scene: return
	left_melee_weapon = second_weapon_scene.instantiate()
	add_child(left_melee_weapon)
	GameData.apply_to_melee(left_melee_weapon)
	if second_weapon and second_weapon.get("active_scene"):
		left_melee_weapon.switch_weapon(second_weapon.active_scene)

func _create_furia_timer() -> void:
	furia_timer = Timer.new()
	furia_timer.one_shot = true
	add_child(furia_timer)
	furia_timer.timeout.connect(_on_furia_timeout)

func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func _on_dash_timer_timeout() -> void:
	is_dashing = false
	if not is_furia_active:
		set_collision_mask_value(2, true)
	if GameData.get_active_protocol() == "reflejo_sintetico":
		_spawn_dash_hologram(dash_start_pos)

func take_damage(amount: int, source_name: String = "Infección Lázaro") -> void:
	if GameData.debug_god_mode: return
	if is_dashing: return
	if is_invulnerable: return
	is_invulnerable = true
	
	var base_amount = amount
	if GameData.get_active_protocol() == "circuito_emergencia" and not first_hit_taken_in_room:
		first_hit_taken_in_room = true
		base_amount = int(base_amount * 0.7)
		
	if GameData.get_active_protocol() == "blindaje_reactivo":
		is_blindaje_reactivo_active = true
		if blindaje_reactivo_timer:
			blindaje_reactivo_timer.start(3.0)
			
	var armor = _get_equip_stat("armor", false)
	var perm_armor = GameData.core_upgrades.get("blindaje_compuesto", 0) * 0.2
	if is_blindaje_reactivo_active:
		perm_armor += 2.0
		
	var final_amount = maxi(1, base_amount - int(armor + perm_armor))
	
	if stats.current_health - final_amount <= 0:
		GameData.last_killer = source_name
	
	invuln_timer.start(0.5)
	stats.take_damage(final_amount)
	_show_damage_text(final_amount)
	_play_hurt_sound()
	_animate_damage_vignette()
	_animate_damage_flash()
	
	var thorns_kb = _get_equip_stat("thorns_knockback", false)
	if thorns_kb > 0.0:
		_apply_thorns_knockback(thorns_kb)

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
	
	var dir_x = -1.0 if randf() < 0.5 else 1.0
	var random_x = dir_x * randf_range(15.0, 40.0)
	var random_y = randf_range(-45.0, -60.0)
	
	var tween = get_tree().create_tween().bind_node(floating_node).set_parallel(true)
	tween.tween_property(floating_node, "global_position", floating_node.global_position + Vector2(random_x, random_y), 0.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
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
	
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
		
	anim_sprite.modulate = Color.RED
	_flash_tween = create_tween()
	_flash_tween.tween_property(anim_sprite, "modulate", _default_modulate, 0.5)

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
	GameData.has_died_once = true
	GameData.clear_items()
	GameData.save_game()
	_play_death_sound()
	_show_death_screen()

func _play_death_sound() -> void:
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = load("res://Audio/Sfx/death_5_sean.wav")
	sfx_player.bus = "Master"
	get_tree().root.add_child(sfx_player)
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)

func _show_death_screen() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 200
	get_tree().root.add_child(canvas)
	
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(root)
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	
	var center_box = CenterContainer.new()
	center_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center_box)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 24)
	main_vbox.modulate.a = 0.0
	center_box.add_child(main_vbox)
	
	var header_vbox = VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 6)
	main_vbox.add_child(header_vbox)
	
	var lbl_title = Label.new()
	lbl_title.text = "HAS MUERTO"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	lbl_title.add_theme_font_size_override("font_size", 64)
	lbl_title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	lbl_title.add_theme_color_override("font_outline_color", Color(0.6, 0.0, 0.0))
	lbl_title.add_theme_constant_override("outline_size", 8)
	header_vbox.add_child(lbl_title)
	
	var lbl_sub = Label.new()
	lbl_sub.text = "VOLVETE MAS FUERTE Y VOLVE A INTENTARLO"
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
	lbl_sub.add_theme_font_size_override("font_size", 18)
	lbl_sub.add_theme_color_override("font_color", Color(0.7, 0.1, 0.1))
	header_vbox.add_child(lbl_sub)
	
	var stats_panel = PanelContainer.new()
	var flat_box = StyleBoxFlat.new()
	flat_box.bg_color = Color(0.08, 0.08, 0.08, 0.95)
	flat_box.border_color = Color(0.25, 0.05, 0.05)
	flat_box.set_border_width_all(2)
	flat_box.set_corner_radius_all(6)
	flat_box.content_margin_left = 24
	flat_box.content_margin_right = 24
	flat_box.content_margin_top = 20
	flat_box.content_margin_bottom = 20
	stats_panel.add_theme_stylebox_override("panel", flat_box)
	main_vbox.add_child(stats_panel)
	
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 16)
	stats_panel.add_child(stats_vbox)
	
	var room_val_lbl = Label.new()
	room_val_lbl.text = "1 - " + str(GameData.current_run_room)
	room_val_lbl.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	room_val_lbl.add_theme_font_size_override("font_size", 24)
	room_val_lbl.add_theme_color_override("font_color", Color.WHITE)
	var row_rooms = _build_stat_row("SALAS RECORRIDAS", "", room_val_lbl)
	stats_vbox.add_child(row_rooms)
	
	var div1 = ColorRect.new()
	div1.color = Color(0.2, 0.1, 0.1, 0.5)
	div1.custom_minimum_size = Vector2(0, 1)
	stats_vbox.add_child(div1)
	
	var kills_val_lbl = Label.new()
	kills_val_lbl.text = str(GameData.run_enemies_killed)
	kills_val_lbl.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	kills_val_lbl.add_theme_font_size_override("font_size", 24)
	kills_val_lbl.add_theme_color_override("font_color", Color.WHITE)
	var row_kills = _build_stat_row("MATASTE", "ENEMIGOS ELIMINADOS", kills_val_lbl)
	stats_vbox.add_child(row_kills)
	
	var div2 = ColorRect.new()
	div2.color = Color(0.2, 0.1, 0.1, 0.5)
	div2.custom_minimum_size = Vector2(0, 1)
	stats_vbox.add_child(div2)
	
	var killer_val_lbl = Label.new()
	killer_val_lbl.text = GameData.last_killer
	killer_val_lbl.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	killer_val_lbl.add_theme_font_size_override("font_size", 20)
	killer_val_lbl.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	var row_killer = _build_stat_row("TE HA MATADO", "FUENTE DE DAÑO", killer_val_lbl)
	stats_vbox.add_child(row_killer)
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(300, 56)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.35, 0.08, 0.08)
	sb_normal.border_color = Color(0.5, 0.1, 0.1)
	sb_normal.set_border_width_all(2)
	sb_normal.set_corner_radius_all(6)
	
	var sb_hover = StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.45, 0.1, 0.1)
	sb_hover.border_color = Color(0.6, 0.15, 0.15)
	sb_hover.set_border_width_all(2)
	sb_hover.set_corner_radius_all(6)
	
	var sb_pressed = StyleBoxFlat.new()
	sb_pressed.bg_color = Color(0.25, 0.05, 0.05)
	sb_pressed.border_color = Color(0.4, 0.08, 0.08)
	sb_pressed.set_border_width_all(2)
	sb_pressed.set_corner_radius_all(6)
	
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(btn_hbox)
	
	var btn_lbl = Label.new()
	btn_lbl.text = "VOLVER AL LABORATORIO"
	btn_lbl.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	btn_lbl.add_theme_font_size_override("font_size", 20)
	btn_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	btn_hbox.add_child(btn_lbl)
	
	var btn_aligner = CenterContainer.new()
	btn_aligner.add_child(btn)
	main_vbox.add_child(btn_aligner)
	
	btn.pressed.connect(_on_return_button_pressed.bind(canvas, bg, main_vbox))
	
	var footer_hbox = HBoxContainer.new()
	footer_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(footer_hbox)
	
	var footer_lbl = Label.new()
	footer_lbl.text = "CHATARRA OBTENIDA EN ESTA RUN: " + str(GameData.run_scrap_collected)
	footer_lbl.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
	footer_lbl.add_theme_font_size_override("font_size", 16)
	footer_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	footer_hbox.add_child(footer_lbl)
	
	var tween = canvas.create_tween().set_parallel(true)
	tween.tween_property(bg, "color", Color(0, 0, 0, 0.85), 0.6)
	tween.tween_property(main_vbox, "modulate:a", 1.0, 0.5).set_delay(0.2)

func _build_stat_row(title: String, subtitle: String, value_node: Control) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(450, 48)
	
	var left_box = HBoxContainer.new()
	left_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	left_box.add_theme_constant_override("separation", 12)
	row.add_child(left_box)
	
	var text_box = VBoxContainer.new()
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override("separation", 0)
	left_box.add_child(text_box)
	
	var lbl_title = Label.new()
	lbl_title.text = title
	lbl_title.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
	lbl_title.add_theme_font_size_override("font_size", 16)
	lbl_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	text_box.add_child(lbl_title)
	
	if subtitle != "":
		var lbl_sub = Label.new()
		lbl_sub.text = subtitle
		lbl_sub.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
		lbl_sub.add_theme_font_size_override("font_size", 11)
		lbl_sub.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		text_box.add_child(lbl_sub)
		
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	
	row.add_child(value_node)
	return row

func _on_return_button_pressed(canvas: CanvasLayer, bg: ColorRect, main_vbox: VBoxContainer) -> void:
	var tween = canvas.create_tween().set_parallel(true)
	tween.tween_property(bg, "color", Color(0, 0, 0, 0), 0.5)
	tween.tween_property(main_vbox, "modulate:a", 0.0, 0.4)
	tween.chain().tween_callback(func():
		canvas.queue_free()
		GameData.clear_items()
		SceneTransition.change_scene("res://Scenes/Rooms/lab_room.tscn")
	)

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
	if keycode == KEY_F3:
		_cheat_bestia_items()
	if keycode == KEY_F4:
		_cheat_trituradora_items()
	if keycode == KEY_F5:
		_cheat_minigun_items()
	if keycode == KEY_F6:
		_toggle_debug_scene()

func _toggle_debug_scene() -> void:
	var current_scene_path = get_tree().current_scene.scene_file_path
	if current_scene_path == "res://Scenes/Rooms/debug_scene.tscn":
		_return_to_previous_scene()
		return
	
	_enter_debug_scene(current_scene_path)

func _return_to_previous_scene() -> void:
	var target = GameData.previous_scene_path
	if target == "" or target == "res://Scenes/Rooms/debug_scene.tscn":
		target = "res://Scenes/Rooms/lab_room.tscn"
	SceneTransition.change_scene(target)

func _enter_debug_scene(current_path: String) -> void:
	GameData.previous_scene_path = current_path
	SceneTransition.change_scene("res://Scenes/Rooms/debug_scene.tscn")


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

func _cheat_bestia_items() -> void:
	var inventory_node = get_node_or_null("Inventory")
	if not inventory_node:
		return
	var caninas = load("res://Art/Items/Player/Legs/Item3_PiernasCaninas.tres") as ItemData
	var armado = load("res://Art/Items/Player/Arms/Item4_BrazoArmado.tres") as ItemData
	var ligero = load("res://Art/Items/Player/Body/Item4_TorsoLigero.tres") as ItemData
	_add_item_if_valid(inventory_node, caninas)
	_add_item_if_valid(inventory_node, armado)
	_add_item_if_valid(inventory_node, ligero)
	print("Bestia de Caza cheated items added to inventory!")

func _cheat_trituradora_items() -> void:
	var inventory_node = get_node_or_null("Inventory")
	if not inventory_node:
		return
	var blindado = load("res://Art/Items/Player/Body/Item2_TorsoBlindado.tres") as ItemData
	var rodantes = load("res://Art/Items/Player/Legs/Item2_PiernasRodantes.tres") as ItemData
	var reforzado = load("res://Art/Items/Player/Arms/Item2_BrazoReforzado.tres") as ItemData
	_add_item_if_valid(inventory_node, blindado)
	_add_item_if_valid(inventory_node, rodantes)
	_add_item_if_valid(inventory_node, reforzado)
	print("Trituradora Biomecanica cheated items added to inventory!")

func _cheat_minigun_items() -> void:
	var inventory_node = get_node_or_null("Inventory")
	if not inventory_node:
		return
	var mezcladora = load("res://Art/Items/Weapons/Item1.tres") as ItemData
	var motocicleta = load("res://Art/Items/Weapons/Item6.tres") as ItemData
	var sierra = load("res://Art/Items/Weapons/Item9_SierraCircular.tres") as ItemData
	_add_item_if_valid(inventory_node, mezcladora)
	_add_item_if_valid(inventory_node, motocicleta)
	_add_item_if_valid(inventory_node, sierra)
	print("Minigun cheated items added to inventory!")

func _play_dash_sound() -> void:
	var dash_sound = get_node_or_null("Dash")
	if not dash_sound: return
	if not dash_sound.has_method("play"): return
	dash_sound.play()

func _update_minigun_hold_time(delta: float) -> void:
	if _is_minigun_active() and Input.is_action_pressed("shoot"):
		minigun_hold_time += delta
	else:
		minigun_hold_time = 0.0

func _is_minigun_active() -> bool:
	var equip = get_node_or_null("Equipment")
	var active_weapon_id = get_active_ranged_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, true)
	return active_syns.has("minigun")

func _get_minigun_level() -> int:
	if minigun_hold_time >= 3.0:
		return 3
	if minigun_hold_time >= 1.5:
		return 2
	if minigun_hold_time > 0.0:
		return 1
	return 0

func _get_minigun_stat_bonus(stat_name: String) -> float:
	if not _is_minigun_active():
		return 0.0
	var lvl = _get_minigun_level()
	if lvl == 0:
		return 0.0
	return _calculate_minigun_bonus(stat_name, lvl)

func _calculate_minigun_bonus(stat_name: String, lvl: int) -> float:
	if stat_name == "damage_multiplier":
		return _get_minigun_damage_bonus(lvl)
	if stat_name == "attack_speed":
		return _get_minigun_speed_bonus(lvl)
	if stat_name == "crit_chance":
		return _get_minigun_crit_bonus(lvl)
	return 0.0

func _get_minigun_damage_bonus(lvl: int) -> float:
	if lvl == 1:
		return 0.10
	if lvl == 2:
		return 0.25
	if lvl == 3:
		return 0.40
	return 0.0

func _get_minigun_speed_bonus(lvl: int) -> float:
	if lvl == 1:
		return 0.10
	if lvl == 2:
		return 0.25
	if lvl == 3:
		return 0.60
	return 0.0

func _get_minigun_crit_bonus(lvl: int) -> float:
	if lvl == 2:
		return 0.10
	if lvl == 3:
		return 0.15
	return 0.0

func _get_fragmentation_chance() -> float:
	if _is_minigun_active() and _get_minigun_level() == 3:
		return 0.20
	return 0.0

func _initialize_protocols() -> void:
	first_hit_taken_in_room = false
	
	if GameData.get_active_protocol() == "enjambre_residual":
		_spawn_allied_bee()
		
	if GameData.get_active_protocol() == "sobrecarga" and get_tree().current_scene and get_tree().current_scene.has_method("_clear_room"):
		_activate_sobrecarga()

func _spawn_allied_bee() -> void:
	var bee_script = load("res://Scripts/Player/allied_bee.gd")
	if not bee_script:
		return
	var bee = CharacterBody2D.new()
	bee.set_script(bee_script)
	bee.global_position = global_position + Vector2(-40, -40)
	get_tree().current_scene.call_deferred("add_child", bee)

func _activate_sobrecarga() -> void:
	GameData.temporary_damage_multiplier = 1.10
	_apply_game_data_upgrades()
	
	var t = get_tree().create_timer(5.0)
	t.timeout.connect(func():
		GameData.temporary_damage_multiplier = 1.0
		_apply_game_data_upgrades()
	)

func _spawn_dash_hologram(start_pos: Vector2) -> void:
	if not anim_sprite:
		return
	var holo = Sprite2D.new()
	if anim_sprite.sprite_frames and anim_sprite.animation:
		var frame_texture = anim_sprite.sprite_frames.get_frame_texture(anim_sprite.animation, anim_sprite.frame)
		holo.texture = frame_texture
	holo.global_position = start_pos
	holo.modulate = Color(0.0, 0.7, 1.0, 0.7)
	holo.scale = anim_sprite.scale
	holo.flip_h = anim_sprite.flip_h
	get_tree().current_scene.add_child(holo)
	
	var targets = get_tree().get_nodes_in_group("enemy")
	var target_dir = Vector2.RIGHT
	if not targets.is_empty():
		var nearest = targets[0]
		var min_d = start_pos.distance_to(nearest.global_position)
		for t in targets:
			var d = start_pos.distance_to(t.global_position)
			if d < min_d:
				nearest = t
				min_d = d
		target_dir = start_pos.direction_to(nearest.global_position)
	else:
		target_dir = dash_dir
		
	var p_scene = projectile_scene
	if active_weapon:
		p_scene = _get_weapon_proj_scene(p_scene)
		
	var dmg = (10.0 + _get_equip_stat("damage")) * (1.0 + _get_equip_stat("damage_multiplier"))
	if active_weapon:
		dmg = (_get_weapon_damage() + _get_equip_stat("damage")) * (_get_weapon_damage_multiplier() + _get_equip_stat("damage_multiplier"))
		
	_spawn_bullets(p_scene, 1, 0.0, target_dir, dmg, 500.0, start_pos, 0, 0.0, 2.0, 3.0)
	
	var tween = create_tween()
	tween.tween_property(holo, "modulate:a", 0.0, 0.4)
	tween.chain().tween_callback(holo.queue_free)
